from typing import Dict, Any, Optional
from datetime import datetime
import logging
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.lib.units import mm
from reportlab.lib.colors import HexColor, black, white
from reportlab.platypus import SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle, PageBreak
from reportlab.lib.enums import TA_CENTER, TA_LEFT, TA_RIGHT
from reportlab.lib import colors
import tempfile
import os
import io

logger = logging.getLogger(__name__)

class PDFService:
    """Service for generating PDF dossiers from review data using ReportLab"""

    def __init__(self):
        self.styles = getSampleStyleSheet()
        self.page_size = A4
        self.margin = 20 * mm  # 20mm margins
        
        # Define custom styles
        self.title_style = ParagraphStyle(
            'CustomTitle',
            parent=self.styles['Heading1'],
            fontSize=16,
            spaceAfter=12,
            textColor=black,
            alignment=TA_LEFT
        )
        
        self.subtitle_style = ParagraphStyle(
            'CustomSubtitle',
            parent=self.styles['Heading2'],
            fontSize=12,
            spaceAfter=6,
            textColor=colors.grey,
            alignment=TA_LEFT
        )
        
        self.normal_style = ParagraphStyle(
            'CustomNormal',
            parent=self.styles['Normal'],
            fontSize=10,
            spaceAfter=6,
            textColor=black,
            alignment=TA_LEFT
        )
        
        # RAG color mapping
        self.rag_colors = {
            'GREEN': HexColor('#EAF3DE'),
            'AMBER': HexColor('#FAEEDA'),
            'RED': HexColor('#FCEBEB')
        }
        
        self.rag_text_colors = {
            'GREEN': HexColor('#27500A'),
            'AMBER': HexColor('#633806'),
            'RED': HexColor('#501313')
        }

    def _get_rag_color(self, rag_label: str) -> tuple:
        """Get background and text colors for RAG label"""
        bg_color = self.rag_colors.get(rag_label.upper(), colors.white)
        text_color = self.rag_text_colors.get(rag_label.upper(), black)
        return bg_color, text_color

    def generate_executive_summary_content(self, review_data: Dict[str, Any]) -> list:
        """Generate PDF content elements for executive summary"""
        content = []
        
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
            'approve': ('Approve', 'GREEN'),
            'approve_with_conditions': ('Approve with conditions', 'AMBER'),
            'conditional_approval': ('Approve with conditions', 'AMBER'),
            'reject': ('Reject', 'RED'),
            'defer': ('Defer', 'AMBER'),
            'return': ('Return', 'AMBER'),
            'pending': ('Pending', 'AMBER')
        }
        
        decision_text, decision_rag = decision_map.get(decision, ('Pending', 'AMBER'))
        
        # Calculate domain statistics
        domain_summaries = review_data.get('domain_summaries', {})
        green_count = sum(1 for d in domain_summaries.values() if d.get('rag_label') == 'GREEN')
        amber_count = sum(1 for d in domain_summaries.values() if d.get('rag_label') == 'AMBER')
        red_count = sum(1 for d in domain_summaries.values() if d.get('rag_label') == 'RED')
        
        # Check for blockers
        blockers = review_data.get('blockers', [])
        has_blocker = len(blockers) > 0
        blocker_text = f"{red_count} domain Red - BLOCKER" if has_blocker else f"{red_count} domain Red"
        
        # Header section
        content.append(Spacer(1, 20))
        
        # Title and subtitle
        title_data = [
            [Paragraph(f"<b>{solution_name}</b>", self.title_style)],
            [Paragraph(f"PRE-ARB DOSSIER", self.subtitle_style)],
            [Paragraph(f"{arb_ref} · EA: {ea_name} · Review: {review_date}", self.normal_style)]
        ]
        
        title_table = Table(title_data, colWidths=[180*mm])
        title_table.setStyle(TableStyle([
            ('ALIGN', (0, 0), (-1, -1), 'LEFT'),
            ('VALIGN', (0, 0), (-1, -1), 'TOP'),
            ('BOTTOMPADDING', (0, 0), (-1, -1), 6),
        ]))
        content.append(title_table)
        
        content.append(Spacer(1, 20))
        
        # Decision section
        decision_bg, decision_text_color = self._get_rag_color(decision_rag)
        decision_data = [
            [Paragraph("RECOMMENDED DECISION", self.subtitle_style)],
            [Paragraph(f"⚠ {decision_text}", self.title_style)]
        ]
        
        decision_table = Table(decision_data, colWidths=[80*mm])
        decision_table.setStyle(TableStyle([
            ('ALIGN', (0, 0), (-1, -1), 'CENTER'),
            ('VALIGN', (0, 0), (-1, -1), 'MIDDLE'),
            ('BACKGROUND', (0, 0), (-1, -1), decision_bg),
            ('TEXTCOLOR', (0, 0), (-1, -1), decision_text_color),
            ('GRID', (0, 0), (-1, -1), 1, decision_text_color),
            ('TOPPADDING', (0, 0), (-1, -1), 8),
            ('BOTTOMPADDING', (0, 0), (-1, -1), 8),
            ('LEFTPADDING', (0, 0), (-1, -1), 12),
            ('RIGHTPADDING', (0, 0), (-1, -1), 12),
        ]))
        content.append(decision_table)
        
        content.append(Spacer(1, 15))
        
        # Aggregate readiness section
        content.append(Paragraph("<b>Aggregate readiness</b>", self.subtitle_style))
        
        aggregate_data = [
            [f"{green_count} domains Green"],
            [f"{amber_count} domains Amber"],
            [f"{blocker_text}"]
        ]
        
        aggregate_table = Table(aggregate_data, colWidths=[60*mm])
        aggregate_table.setStyle(TableStyle([
            ('ALIGN', (0, 0), (-1, -1), 'CENTER'),
            ('VALIGN', (0, 0), (-1, -1), 'MIDDLE'),
            ('BACKGROUND', (0, 0), (0, 0), self.rag_colors['GREEN']),
            ('TEXTCOLOR', (0, 0), (0, 0), self.rag_text_colors['GREEN']),
            ('BACKGROUND', (0, 1), (0, 1), self.rag_colors['AMBER']),
            ('TEXTCOLOR', (0, 1), (0, 1), self.rag_text_colors['AMBER']),
            ('BACKGROUND', (0, 2), (0, 2), self.rag_colors['RED']),
            ('TEXTCOLOR', (0, 2), (0, 2), self.rag_text_colors['RED']),
            ('GRID', (0, 0), (-1, -1), 1, black),
            ('TOPPADDING', (0, 0), (-1, -1), 6),
            ('BOTTOMPADDING', (0, 0), (-1, -1), 6),
            ('LEFTPADDING', (0, 0), (-1, -1), 8),
            ('RIGHTPADDING', (0, 0), (-1, -1), 8),
        ]))
        content.append(aggregate_table)
        
        content.append(Spacer(1, 15))
        
        # Rationale section
        content.append(Paragraph("<b>Agent rationale:</b> " + decision_rationale, self.normal_style))
        content.append(Spacer(1, 15))
        
        # Domain scorecard section
        content.append(Paragraph("DOMAIN SCORECARD", self.subtitle_style))
        content.append(Spacer(1, 10))
        
        # Domain rows
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
        
        domain_table_data = []
        for domain_key, domain_name in domain_order:
            domain_data = domain_summaries.get(domain_key)
            if not domain_data:
                continue
                
            score = domain_data.get('score', 3)
            rag_label = domain_data.get('rag_label', 'AMBER')
            executive_summary = domain_data.get('executive_summary', '')
            
            # Add blocker indicator for security domain
            blocker_indicator = " BLOCKER" if domain_key == 'security' and has_blocker else ""
            
            domain_bg, domain_text_color = self._get_rag_color(rag_label)
            
            domain_table_data.append([
                Paragraph(f"{score}/5", self.normal_style),
                Paragraph(f"<b>{domain_name}</b>{blocker_indicator}", self.normal_style),
                Paragraph(rag_label, self.normal_style),
                Paragraph(executive_summary, self.normal_style)
            ])
        
        if domain_table_data:
            domain_table = Table(domain_table_data, colWidths=[15*mm, 45*mm, 25*mm, 95*mm])
            domain_table.setStyle(TableStyle([
                ('ALIGN', (0, 0), (-1, -1), 'LEFT'),
                ('VALIGN', (0, 0), (-1, -1), 'TOP'),
                ('GRID', (0, 0), (-1, -1), 1, colors.grey),
                ('TOPPADDING', (0, 0), (-1, -1), 8),
                ('BOTTOMPADDING', (0, 0), (-1, -1), 8),
                ('LEFTPADDING', (0, 0), (-1, -1), 6),
                ('RIGHTPADDING', (0, 0), (-1, -1), 6),
            ]))
            content.append(domain_table)
        
        # Blocker callout
        if has_blocker:
            content.append(Spacer(1, 15))
            blocker = blockers[0]  # Show first blocker
            
            blocker_data = [
                [Paragraph("BLOCKER — MUST RESOLVE BEFORE ARB", self.subtitle_style)],
                [Paragraph(f"{blocker.get('blocker_id', 'BLK-01')} · {blocker.get('title', 'Security issue')}.", self.normal_style)]
            ]
            
            blocker_table = Table(blocker_data, colWidths=[180*mm])
            blocker_table.setStyle(TableStyle([
                ('ALIGN', (0, 0), (-1, -1), 'LEFT'),
                ('VALIGN', (0, 0), (-1, -1), 'TOP'),
                ('BACKGROUND', (0, 0), (-1, -1), self.rag_colors['RED']),
                ('TEXTCOLOR', (0, 0), (-1, -1), self.rag_text_colors['RED']),
                ('GRID', (0, 0), (-1, -1), 1, self.rag_text_colors['RED']),
                ('TOPPADDING', (0, 0), (-1, -1), 10),
                ('BOTTOMPADDING', (0, 0), (-1, -1), 10),
                ('LEFTPADDING', (0, 0), (-1, -1), 12),
                ('RIGHTPADDING', (0, 0), (-1, -1), 12),
            ]))
            content.append(blocker_table)
        
        return content

    def generate_dossier_pdf(self, review_data: Dict[str, Any]) -> bytes:
        """Generate complete PDF dossier for a review"""
        try:
            # Create a buffer for the PDF
            buffer = io.BytesIO()
            
            # Create the PDF document
            doc = SimpleDocTemplate(
                buffer,
                pagesize=self.page_size,
                leftMargin=self.margin,
                rightMargin=self.margin,
                topMargin=self.margin,
                bottomMargin=self.margin
            )
            
            # Generate content
            content = self.generate_executive_summary_content(review_data)
            
            # Build the PDF
            doc.build(content)
            
            # Get the PDF bytes
            pdf_bytes = buffer.getvalue()
            buffer.close()
            
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
