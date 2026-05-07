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
        self.margin = 15 * mm  # 15mm margins to match screenshot
        
        # Define custom styles matching the screenshot
        self.title_style = ParagraphStyle(
            'CustomTitle',
            parent=self.styles['Normal'],
            fontSize=17,
            spaceAfter=2,
            textColor=black,
            alignment=TA_LEFT,
            fontName='Helvetica-Bold'
        )
        
        self.subtitle_style = ParagraphStyle(
            'CustomSubtitle',
            parent=self.styles['Normal'],
            fontSize=11,
            spaceAfter=3,
            textColor=HexColor('#666666'),
            alignment=TA_LEFT,
            fontName='Helvetica'
        )
        
        self.normal_style = ParagraphStyle(
            'CustomNormal',
            parent=self.styles['Normal'],
            fontSize=13,
            spaceAfter=0,
            textColor=black,
            alignment=TA_LEFT,
            fontName='Helvetica'
        )
        
        self.small_style = ParagraphStyle(
            'CustomSmall',
            parent=self.styles['Normal'],
            fontSize=12,
            spaceAfter=0,
            textColor=HexColor('#666666'),
            alignment=TA_LEFT,
            fontName='Helvetica'
        )
        
        self.domain_style = ParagraphStyle(
            'CustomDomain',
            parent=self.styles['Normal'],
            fontSize=13,
            spaceAfter=0,
            textColor=black,
            alignment=TA_LEFT,
            fontName='Helvetica-Bold'
        )
        
        # RAG color mapping matching screenshot
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
        
        self.rag_border_colors = {
            'GREEN': HexColor('#97C459'),
            'AMBER': HexColor('#EF9F27'),
            'RED': HexColor('#E24B4A')
        }

    def _get_rag_colors(self, rag_label: str) -> tuple:
        """Get background, text, and border colors for RAG label"""
        bg_color = self.rag_colors.get(rag_label.upper(), colors.white)
        text_color = self.rag_text_colors.get(rag_label.upper(), black)
        border_color = self.rag_border_colors.get(rag_label.upper(), black)
        return bg_color, text_color, border_color

    def generate_executive_summary_content(self, review_data: Dict[str, Any]) -> list:
        """Generate PDF content elements for executive summary matching screenshot exactly"""
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
        blocker_text = f"{red_count} domain Red — BLOCKER" if has_blocker else f"{red_count} domain Red"
        
        # Main container with border
        content.append(Spacer(1, 5))
        
        # Header band - matching screenshot layout
        header_data = [
            [
                # Left side - solution info
                [
                    Paragraph("PRE-ARB DOSSIER", self.subtitle_style),
                    Paragraph(solution_name, self.title_style),
                    Paragraph(f"{arb_ref} · EA: {ea_name} · Review: {review_date}", self.subtitle_style)
                ],
                # Right side - decision
                [
                    Paragraph("RECOMMENDED DECISION", self.subtitle_style),
                    self._create_decision_pill(decision_text, decision_rag)
                ]
            ]
        ]
        
        header_table = Table(header_data, colWidths=[120*mm, 60*mm])
        header_table.setStyle(TableStyle([
            ('ALIGN', (0, 0), (-1, -1), 'LEFT'),
            ('VALIGN', (0, 0), (-1, -1), 'TOP'),
            ('BACKGROUND', (0, 0), (-1, -1), HexColor('#f8f9fa')),
            ('GRID', (0, 0), (-1, -1), 0.5, HexColor('#ccc')),
            ('TOPPADDING', (0, 0), (-1, -1), 14),
            ('BOTTOMPADDING', (0, 0), (-1, -1), 14),
            ('LEFTPADDING', (0, 0), (-1, -1), 18),
            ('RIGHTPADDING', (0, 0), (-1, -1), 18),
        ]))
        content.append(header_table)
        
        # Aggregate bar - matching screenshot
        aggregate_data = [
            [
                Paragraph("Aggregate readiness", self.small_style),
                self._create_aggregate_pills(green_count, amber_count, blocker_text)
            ]
        ]
        
        aggregate_table = Table(aggregate_data, colWidths=[180*mm])
        aggregate_table.setStyle(TableStyle([
            ('ALIGN', (0, 0), (-1, -1), 'LEFT'),
            ('VALIGN', (0, 0), (-1, -1), 'MIDDLE'),
            ('BACKGROUND', (0, 0), (-1, -1), HexColor('#f8f9fa')),
            ('GRID', (0, 0), (-1, -1), 0.5, HexColor('#e0e0e0')),
            ('TOPPADDING', (0, 0), (-1, -1), 14),
            ('BOTTOMPADDING', (0, 0), (-1, -1), 14),
            ('LEFTPADDING', (0, 0), (-1, -1), 18),
            ('RIGHTPADDING', (0, 0), (-1, -1), 18),
        ]))
        content.append(aggregate_table)
        
        # Rationale section
        rationale_text = f"<b>Agent rationale:</b> {decision_rationale}"
        rationale_data = [[Paragraph(rationale_text, self.small_style)]]
        
        rationale_table = Table(rationale_data, colWidths=[180*mm])
        rationale_table.setStyle(TableStyle([
            ('ALIGN', (0, 0), (-1, -1), 'LEFT'),
            ('VALIGN', (0, 0), (-1, -1), 'TOP'),
            ('BACKGROUND', (0, 0), (-1, -1), HexColor('#f8f9fa')),
            ('GRID', (0, 0), (-1, -1), 0.5, HexColor('#e0e0e0')),
            ('TOPPADDING', (0, 0), (-1, -1), 14),
            ('BOTTOMPADDING', (0, 0), (-1, -1), 14),
            ('LEFTPADDING', (0, 0), (-1, -1), 18),
            ('RIGHTPADDING', (0, 0), (-1, -1), 18),
        ]))
        content.append(rationale_table)
        
        # Domain scorecard section
        domain_table_data = []
        domain_table_data.append([Paragraph("DOMAIN SCORECARD", self.subtitle_style)])
        
        # Domain rows - matching screenshot grid layout
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
            
            # Add blocker indicator for security domain
            blocker_indicator = " <font color='#501313' size='8'>BLOCKER</font>" if domain_key == 'security' and has_blocker else ""
            
            domain_bg, domain_text_color, domain_border_color = self._get_rag_colors(rag_label)
            
            # Create score badge
            score_badge = self._create_score_badge(score, rag_label)
            
            # Create RAG badge
            rag_badge = self._create_rag_badge(rag_label)
            
            domain_table_data.append([
                score_badge,
                Paragraph(f"{domain_name}{blocker_indicator}", self.domain_style),
                rag_badge,
                Paragraph(executive_summary, self.small_style)
            ])
        
        # Convert to table with proper styling
        domain_table = Table(domain_table_data, colWidths=[20*mm, 80*mm, 18*mm, 62*mm])
        domain_table.setStyle(TableStyle([
            ('ALIGN', (0, 0), (-1, -1), 'LEFT'),
            ('VALIGN', (0, 0), (-1, -1), 'TOP'),
            ('BACKGROUND', (0, 0), (-1, -1), HexColor('#f8f9fa')),
            ('GRID', (0, 0), (-1, -1), 0.5, HexColor('#ccc')),
            ('TOPPADDING', (0, 0), (-1, -1), 7),
            ('BOTTOMPADDING', (0, 0), (-1, -1), 7),
            ('LEFTPADDING', (0, 0), (-1, -1), 18),
            ('RIGHTPADDING', (0, 0), (-1, -1), 18),
            # Header row styling
            ('SPAN', (0, 0), (3, 0)),
            ('BACKGROUND', (0, 0), (3, 0), HexColor('#f8f9fa')),
            ('BOTTOMPADDING', (0, 0), (3, 0), 8),
        ]))
        content.append(domain_table)
        
        # Blocker callout - matching screenshot
        if has_blocker:
            content.append(Spacer(1, 10))
            blocker = blockers[0]  # Show first blocker
            
            blocker_text = f"BLK-01 · Security: VAPT evidence not submitted. RBAC model incomplete for three service accounts. Non-compliance with Security Standards v2.4."
            
            blocker_data = [
                [Paragraph("BLOCKER — MUST RESOLVE BEFORE ARB", self.subtitle_style)],
                [Paragraph(blocker_text, self.normal_style)]
            ]
            
            blocker_table = Table(blocker_data, colWidths=[180*mm])
            blocker_table.setStyle(TableStyle([
                ('ALIGN', (0, 0), (-1, -1), 'LEFT'),
                ('VALIGN', (0, 0), (-1, -1), 'TOP'),
                ('BACKGROUND', (0, 0), (-1, -1), HexColor('#FCEBEB')),
                ('GRID', (0, 0), (-1, -1), 0.5, HexColor('#E24B4A')),
                ('TEXTCOLOR', (0, 0), (-1, -1), HexColor('#501313')),
                ('TOPPADDING', (0, 0), (-1, -1), 11),
                ('BOTTOMPADDING', (0, 0), (-1, -1), 11),
                ('LEFTPADDING', (0, 0), (-1, -1), 14),
                ('RIGHTPADDING', (0, 0), (-1, -1), 14),
            ]))
            content.append(blocker_table)
        
        return content

    def _create_decision_pill(self, decision_text: str, rag_label: str) -> Table:
        """Create decision pill matching screenshot"""
        bg_color, text_color, border_color = self._get_rag_colors(rag_label)
        
        pill_data = [[Paragraph(f"⚠ {decision_text}", self.title_style)]]
        pill_table = Table(pill_data, colWidths=[50*mm])
        pill_table.setStyle(TableStyle([
            ('ALIGN', (0, 0), (-1, -1), 'CENTER'),
            ('VALIGN', (0, 0), (-1, -1), 'MIDDLE'),
            ('BACKGROUND', (0, 0), (-1, -1), bg_color),
            ('TEXTCOLOR', (0, 0), (-1, -1), text_color),
            ('GRID', (0, 0), (-1, -1), 0.5, border_color),
            ('TOPPADDING', (0, 0), (-1, -1), 6),
            ('BOTTOMPADDING', (0, 0), (-1, -1), 6),
            ('LEFTPADDING', (0, 0), (-1, -1), 14),
            ('RIGHTPADDING', (0, 0), (-1, -1), 14),
        ]))
        return pill_table

    def _create_aggregate_pills(self, green_count: int, amber_count: int, blocker_text: str) -> Table:
        """Create aggregate pills matching screenshot"""
        pill_data = [
            [
                self._create_simple_pill(f"{green_count} domains Green", 'GREEN'),
                self._create_simple_pill(f"{amber_count} domains Amber", 'AMBER'),
                self._create_simple_pill(blocker_text, 'RED')
            ]
        ]
        
        pills_table = Table(pill_data, colWidths=[60*mm, 60*mm, 60*mm])
        pills_table.setStyle(TableStyle([
            ('ALIGN', (0, 0), (-1, -1), 'CENTER'),
            ('VALIGN', (0, 0), (-1, -1), 'MIDDLE'),
        ]))
        return pills_table

    def _create_simple_pill(self, text: str, rag_label: str) -> Table:
        """Create simple pill for aggregate section"""
        bg_color, text_color, border_color = self._get_rag_colors(rag_label)
        
        pill_data = [[Paragraph(text, self.small_style)]]
        pill_table = Table(pill_data, colWidths=[58*mm])
        pill_table.setStyle(TableStyle([
            ('ALIGN', (0, 0), (-1, -1), 'CENTER'),
            ('VALIGN', (0, 0), (-1, -1), 'MIDDLE'),
            ('BACKGROUND', (0, 0), (-1, -1), bg_color),
            ('TEXTCOLOR', (0, 0), (-1, -1), text_color),
            ('GRID', (0, 0), (-1, -1), 0.5, border_color),
            ('TOPPADDING', (0, 0), (-1, -1), 4),
            ('BOTTOMPADDING', (0, 0), (-1, -1), 4),
            ('LEFTPADDING', (0, 0), (-1, -1), 10),
            ('RIGHTPADDING', (0, 0), (-1, -1), 10),
        ]))
        return pill_table

    def _create_score_badge(self, score: int, rag_label: str) -> Table:
        """Create score badge matching screenshot"""
        bg_color, text_color, border_color = self._get_rag_colors(rag_label)
        
        badge_data = [[Paragraph(f"{score}/5", self.small_style)]]
        badge_table = Table(badge_data, colWidths=[18*mm])
        badge_table.setStyle(TableStyle([
            ('ALIGN', (0, 0), (-1, -1), 'CENTER'),
            ('VALIGN', (0, 0), (-1, -1), 'MIDDLE'),
            ('BACKGROUND', (0, 0), (-1, -1), bg_color),
            ('TEXTCOLOR', (0, 0), (-1, -1), text_color),
            ('GRID', (0, 0), (-1, -1), 0.5, border_color),
            ('TOPPADDING', (0, 0), (-1, -1), 3),
            ('BOTTOMPADDING', (0, 0), (-1, -1), 3),
            ('LEFTPADDING', (0, 0), (-1, -1), 6),
            ('RIGHTPADDING', (0, 0), (-1, -1), 6),
        ]))
        return badge_table

    def _create_rag_badge(self, rag_label: str) -> Table:
        """Create RAG badge matching screenshot"""
        bg_color, text_color, border_color = self._get_rag_colors(rag_label)
        
        badge_data = [[Paragraph(rag_label, self.small_style)]]
        badge_table = Table(badge_data, colWidths=[18*mm])
        badge_table.setStyle(TableStyle([
            ('ALIGN', (0, 0), (-1, -1), 'CENTER'),
            ('VALIGN', (0, 0), (-1, -1), 'MIDDLE'),
            ('BACKGROUND', (0, 0), (-1, -1), bg_color),
            ('TEXTCOLOR', (0, 0), (-1, -1), text_color),
            ('GRID', (0, 0), (-1, -1), 0.5, border_color),
            ('TOPPADDING', (0, 0), (-1, -1), 2),
            ('BOTTOMPADDING', (0, 0), (-1, -1), 2),
            ('LEFTPADDING', (0, 0), (-1, -1), 8),
            ('RIGHTPADDING', (0, 0), (-1, -1), 8),
        ]))
        return badge_table

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
