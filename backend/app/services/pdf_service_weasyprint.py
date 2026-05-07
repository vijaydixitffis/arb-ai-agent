from typing import Dict, Any, Optional
from datetime import datetime
import logging
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.lib.units import mm
from reportlab.lib.colors import HexColor, black, white
from reportlab.platypus import SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle
from reportlab.platypus.tableofcontents import TableOfContents
from reportlab.lib.enums import TA_CENTER, TA_LEFT, TA_RIGHT
import tempfile
import os

logger = logging.getLogger(__name__)

class PDFService:
    """Service for generating PDF dossiers from review data using ReportLab"""

    def __init__(self):
        self.styles = getSampleStyleSheet()
        self.page_size = A4
        self.margin = 20 * mm  # 20mm margins

    def generate_executive_summary_html(self, review_data: Dict[str, Any]) -> str:
        """Generate HTML for executive summary based on the template"""
        
        # Extract review information
        solution_name = review_data.get('solution_name', 'Unknown Solution')
        arb_ref = review_data.get('arb_ref', 'EARR-2026-0412')
        ea_name = review_data.get('ea_review', {}).get('ea_name', 'Priya Nair')
        reviewed_at = review_data.get('reviewed_at')
        if reviewed_at:
            review_date = datetime.fromisoformat(reviewed_at.replace('Z', '+00:00')).strftime('%d-%b-%Y')
        else:
            review_date = datetime.now().strftime('%d-%b-%Y')
        
        # Get decision information
        decision = review_data.get('decision') or review_data.get('recommended_decision', 'pending')
        aggregate_rag_label = review_data.get('aggregate_rag_label', 'AMBER')
        decision_rationale = review_data.get('decision_rationale', '')
        
        # Map decision to display text and color
        decision_map = {
            'approve': ('Approve', 'rag-g'),
            'approve_with_conditions': ('Approve with conditions', 'rag-a'),
            'conditional_approval': ('Approve with conditions', 'rag-a'),
            'reject': ('Reject', 'rag-r'),
            'defer': ('Defer', 'rag-a'),
            'return': ('Return', 'rag-a'),
            'pending': ('Pending', 'rag-a')
        }
        
        decision_text, decision_class = decision_map.get(decision, ('Pending', 'rag-a'))
        
        # Calculate domain statistics
        domain_summaries = review_data.get('domain_summaries', {})
        green_count = sum(1 for d in domain_summaries.values() if d.get('rag_label') == 'GREEN')
        amber_count = sum(1 for d in domain_summaries.values() if d.get('rag_label') == 'AMBER')
        red_count = sum(1 for d in domain_summaries.values() if d.get('rag_label') == 'RED')
        
        # Check for blockers
        blockers = review_data.get('blockers', [])
        has_blocker = len(blockers) > 0
        blocker_text = ""
        if has_blocker:
            blocker_text = f"{red_count} domain Red — BLOCKER"
        else:
            blocker_text = f"{red_count} domain Red"
        
        # Generate domain rows HTML
        domain_rows_html = ""
        domain_order = [
            ('application', 'Application architecture'),
            ('software', 'Software architecture'),
            ('integration', 'Integration architecture'),
            ('api', 'API architecture'),
            ('security', 'Security architecture'),
            ('data', 'Data architecture'),
            ('infrastructure', 'Infra & platform'),
            ('devsecops', 'Engineering & DevSecOps'),
            ('quality', 'Engineering quality')
        ]
        
        for domain_key, domain_name in domain_order:
            domain_data = domain_summaries.get(domain_key)
            if not domain_data:
                continue
                
            score = domain_data.get('score', 3)
            rag_label = domain_data.get('rag_label', 'AMBER')
            executive_summary = domain_data.get('executive_summary', '')
            
            # Map RAG to CSS class
            rag_class_map = {'GREEN': 'rag-g', 'AMBER': 'rag-a', 'RED': 'rag-r'}
            rag_class = rag_class_map.get(rag_label, 'rag-a')
            
            # Add blocker indicator for security domain
            blocker_indicator = ""
            if domain_key == 'security' and has_blocker:
                blocker_indicator = '<span class="block-pill">BLOCKER</span>'
            
            domain_rows_html += f"""
    <div class="domain-row">
      <span class="rag-badge {rag_class}" style="padding:3px 6px;border-radius:4px;font-size:11px">{score}/5</span>
      <span style="color:var(--color-text-primary);font-weight:500">{domain_name}{blocker_indicator}</span>
      <span class="rag-badge {rag_class}">{rag_label}</span>
      <span style="color:var(--color-text-secondary)">{executive_summary}</span>
    </div>"""
        
        # Generate blocker callout
        blocker_callout_html = ""
        if has_blocker:
            blocker = blockers[0]  # Show first blocker
            blocker_callout_html = f"""
  <!-- Blocker callout -->
  <div style="margin:0 18px 16px;border-radius:var(--border-radius-md);background:#FCEBEB;border:0.5px solid #E24B4A;padding:11px 14px">
    <div style="font-size:11px;font-weight:500;color:#A32D2D;letter-spacing:0.04em;margin-bottom:5px">BLOCKER — MUST RESOLVE BEFORE ARB</div>
    <div style="font-size:13px;color:#501313">{blocker.get('blocker_id', 'BLK-01')} · {blocker.get('title', 'Security issue')}.</div>
  </div>"""

        # Generate complete HTML
        html_template = f"""
<style>
.rag-g{{background:#EAF3DE;color:#27500A;border:0.5px solid #97C459}}
.rag-a{{background:#FAEEDA;color:#633806;border:0.5px solid #EF9F27}}
.rag-r{{background:#FCEBEB;color:#501313;border:0.5px solid #E24B4A}}
.rag-badge{{font-size:11px;font-weight:500;padding:2px 8px;border-radius:999px;white-space:nowrap}}
.score-pill{{display:inline-flex;align-items:center;gap:5px;font-size:12px;padding:4px 10px;border-radius:6px;font-weight:500;border:0.5px solid}}
.domain-row{{display:grid;grid-template-columns:20px 1fr 80px 1fr;gap:8px 12px;align-items:start;padding:7px 0;border-bottom:0.5px solid #e0e0e0;font-size:13px}}
.domain-row:last-child{{border-bottom:none}}
.block-pill{{display:inline-block;font-size:10px;font-weight:500;padding:2px 7px;border-radius:999px;background:#FCEBEB;color:#501313;border:0.5px solid #E24B4A;margin-left:6px}}
</style>

<div style="border-radius:8px;border:0.5px solid #ccc;overflow:hidden;font-family:Arial,sans-serif">

  <!-- Header band -->
  <div style="background:#f8f9fa;padding:14px 18px;display:flex;align-items:center;justify-content:space-between;gap:12px;flex-wrap:wrap">
    <div>
      <div style="font-size:11px;color:#666;margin-bottom:3px;letter-spacing:0.04em">PRE-ARB DOSSIER</div>
      <div style="font-size:17px;font-weight:500;color:#333">{solution_name}</div>
      <div style="font-size:12px;color:#666;margin-top:2px">{arb_ref} · EA: {ea_name} · Review: {review_date}</div>
    </div>
    <div style="text-align:right">
      <div style="font-size:11px;color:#666;margin-bottom:5px">RECOMMENDED DECISION</div>
      <span class="score-pill {decision_class}" style="font-size:13px;padding:6px 14px">⚠ {decision_text}</span>
    </div>
  </div>

  <!-- Aggregate bar -->
  <div style="padding:14px 18px;border-bottom:0.5px solid #e0e0e0;display:flex;gap:16px;flex-wrap:wrap;align-items:center">
    <div style="font-size:12px;color:#666">Aggregate readiness</div>
    <div style="display:flex;gap:6px;flex-wrap:wrap">
      <span class="score-pill rag-g">{green_count} domains Green</span>
      <span class="score-pill rag-a">{amber_count} domains Amber</span>
      <span class="score-pill rag-r">{blocker_text}</span>
    </div>
  </div>

  <!-- Rationale -->
  <div style="padding:14px 18px;border-bottom:0.5px solid #e0e0e0;font-size:13px;color:#666;line-height:1.7">
    <span style="font-weight:500;color:#333">Agent rationale: </span>
    {decision_rationale}
  </div>

  <!-- Domain scorecard -->
  <div style="padding:14px 18px">
    <div style="font-size:11px;font-weight:500;color:#666;letter-spacing:0.04em;margin-bottom:8px">DOMAIN SCORECARD</div>

{domain_rows_html}
  </div>

{blocker_callout_html}

</div>
"""
        return html_template

    def generate_dossier_pdf(self, review_data: Dict[str, Any]) -> bytes:
        """Generate complete PDF dossier for a review"""
        try:
            # Generate executive summary HTML
            executive_summary_html = self.generate_executive_summary_html(review_data)
            
            # Create CSS for PDF
            css = CSS(string="""
                @page {
                    size: A4;
                    margin: 2cm;
                }
                body {
                    font-family: Arial, sans-serif;
                    font-size: 12px;
                    line-height: 1.4;
                    color: #333;
                }
            """)
            
            # Create HTML document
            html_doc = HTML(string=executive_summary_html)
            
            # Generate PDF
            pdf_bytes = html_doc.write_pdf(stylesheets=[css], font_config=self.font_config)
            
            logger.info(f"Generated PDF dossier for review: {review_data.get('id', 'unknown')}")
            return pdf_bytes
            
        except Exception as e:
            logger.error(f"Error generating PDF dossier: {str(e)}")
            raise

    def save_pdf_to_file(self, pdf_bytes: bytes, filename: str) -> str:
        """Save PDF bytes to temporary file and return file path"""
        try:
            with tempfile.NamedTemporaryFile(delete=False, suffix='.pdf') as tmp_file:
                tmp_file.write(pdf_bytes)
                return tmp_file.name
        except Exception as e:
            logger.error(f"Error saving PDF to file: {str(e)}")
            raise

    def cleanup_temp_file(self, file_path: str):
        """Clean up temporary file"""
        try:
            if os.path.exists(file_path):
                os.unlink(file_path)
        except Exception as e:
            logger.warning(f"Error cleaning up temp file {file_path}: {str(e)}")
