import re
from typing import List, Dict, Any, Optional
from pathlib import Path


class MarkdownPrincipleParser:
    """Parser for extracting structured principles from markdown files"""
    
    def __init__(self):
        self.principle_pattern = re.compile(r'### ([A-Z]+-\d+)\s*—\s*(.+)')
        self.header_pattern = re.compile(r'#{1,3}\s+(.+)')
    
    def parse_file(self, file_path: str) -> List[Dict[str, Any]]:
        """
        Parse a markdown file and extract structured principles.
        
        Args:
            file_path: Path to the markdown file
            
        Returns:
            List of principle dictionaries with keys:
            - id: Principle ID (e.g., INT-01)
            - title: Principle title
            - statement: Statement text
            - rationale: Rationale text
            - implications: List of implication points
            - items_to_verify: List of verification items
            - category: Category inferred from ID prefix
        """
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()
        
        return self.parse_content(content)
    
    def parse_content(self, content: str) -> List[Dict[str, Any]]:
        """
        Parse markdown content and extract structured principles.
        
        Args:
            content: Markdown content as string
            
        Returns:
            List of principle dictionaries
        """
        principles = []
        sections = self._split_into_sections(content)
        
        for section in sections:
            principle = self._parse_principle_section(section)
            if principle:
                principles.append(principle)
        
        return principles
    
    def _split_into_sections(self, content: str) -> List[str]:
        """Split content into principle sections based on ### headers"""
        # Split by ### headers
        sections = re.split(r'\n###\s', content)
        
        # Filter out empty sections and the header/intro
        filtered_sections = []
        for section in sections:
            section = section.strip()
            if section and not section.startswith('#'):
                # Add the ### back for consistency
                section = '### ' + section
                filtered_sections.append(section)
        
        return filtered_sections
    
    def _parse_principle_section(self, section: str) -> Optional[Dict[str, Any]]:
        """Parse a single principle section"""
        lines = section.split('\n')
        
        # Extract principle ID and title from first line
        first_line = lines[0].strip()
        match = self.principle_pattern.match(first_line)
        if not match:
            return None
        
        principle_id = match.group(1)
        title = match.group(2)
        
        # Parse the content
        statement = ""
        rationale = ""
        implications = []
        items_to_verify = []
        
        current_section = None
        current_content = []
        
        for line in lines[1:]:
            line = line.strip()
            
            # Check for section headers
            if line.startswith('**Statement**'):
                if current_section:
                    statement, rationale, implications, items_to_verify = self._process_current_section(
                        current_section, current_content, statement, rationale, implications, items_to_verify
                    )
                current_section = 'statement'
                current_content = []
            elif line.startswith('**Rationale**'):
                if current_section:
                    statement, rationale, implications, items_to_verify = self._process_current_section(
                        current_section, current_content, statement, rationale, implications, items_to_verify
                    )
                current_section = 'rationale'
                current_content = []
            elif line.startswith('**Implications**'):
                if current_section:
                    statement, rationale, implications, items_to_verify = self._process_current_section(
                        current_section, current_content, statement, rationale, implications, items_to_verify
                    )
                current_section = 'implications'
                current_content = []
            elif line.startswith('**Items to Verify in Review**'):
                if current_section:
                    statement, rationale, implications, items_to_verify = self._process_current_section(
                        current_section, current_content, statement, rationale, implications, items_to_verify
                    )
                current_section = 'items_to_verify'
                current_content = []
            elif line.startswith('---'):
                # Section separator, ignore
                continue
            elif line:
                # Content line
                current_content.append(line)
        
        # Process the last section
        if current_section:
            statement, rationale, implications, items_to_verify = self._process_current_section(
                current_section, current_content, statement, rationale, implications, items_to_verify
            )
        
        # Determine category from principle ID
        category = self._infer_category(principle_id)
        
        return {
            'id': principle_id,
            'title': title,
            'statement': statement,
            'rationale': rationale,
            'implications': implications,
            'items_to_verify': items_to_verify,
            'category': category
        }
    
    def _process_current_section(self, section: str, content: List[str], 
                                  statement: str, rationale: str, 
                                  implications: List[str], items_to_verify: List[str]) -> tuple:
        """Process accumulated content for a section and return updated values"""
        text = ' '.join(content).strip()
        
        if section == 'statement':
            statement = text
        elif section == 'rationale':
            rationale = text
        elif section == 'implications':
            # Split by bullet points
            for line in content:
                line = line.strip()
                if line.startswith('-'):
                    implications.append(line[1:].strip())
        elif section == 'items_to_verify':
            # Split by checkbox items
            for line in content:
                line = line.strip()
                if line.startswith('-'):
                    # Remove checkbox markers
                    clean_line = line[1:].strip()
                    clean_line = re.sub(r'\[.\]\s*', '', clean_line)
                    items_to_verify.append(clean_line)
        
        return statement, rationale, implications, items_to_verify
    
    def _infer_category(self, principle_id: str) -> str:
        """Infer category from principle ID prefix"""
        prefix = principle_id.split('-')[0]
        
        category_map = {
            'INT': 'General',
            'API': 'API-Based',
            'FILE': 'File-Based',
            'MSG': 'Message-Based',
            'SEC': 'Security',
            'GOV': 'Governance',
            'OPS': 'Operations',
            'G': 'General',
            'B': 'Business',
            'S': 'Security',
            'A': 'Application',
            'SW': 'Software',
            'D': 'Data',
            'I': 'Infrastructure'
        }
        
        return category_map.get(prefix, 'General')
    
    def extract_arb_weight(self, file_path: str) -> Dict[str, str]:
        """
        Extract ARB weights from the quick reference table in the markdown file.
        
        Args:
            file_path: Path to the markdown file
            
        Returns:
            Dictionary mapping principle IDs to ARB weights
        """
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()
        
        weights = {}
        
        # Find the quick reference table
        table_match = re.search(r'\| ID \| Principle \| Category \| ARB Weight \|(.+?)(?=\n\n|\Z)', content, re.DOTALL)
        if table_match:
            table_content = table_match.group(1)
            # Parse table rows
            rows = re.findall(r'\| ([A-Z]+-\d+) \| (.+) \| (.+) \| (.+) \|', table_content)
            for row in rows:
                principle_id = row[0]
                weight = row[3].strip()
                weights[principle_id] = weight
        
        return weights


# Global instance
markdown_parser = MarkdownPrincipleParser()
