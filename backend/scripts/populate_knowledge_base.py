#!/usr/bin/env python3
"""
Script to populate knowledge_base table from markdown files in knowledge-base directory
"""

import os
import re
import uuid
import asyncio
from pathlib import Path
from sqlalchemy.orm import Session
from app.core.database import SessionLocal
from app.db.artefact_models import KnowledgeBase

def extract_principles_from_md(content: str, file_path: str) -> list:
    """Extract individual principles from markdown content"""
    principles = []
    
    # Split by principle headers (### PRINCIPLE-ID)
    principle_sections = re.split(r'\n### ([A-Z]+-\d+)', content)
    
    # First element is before first principle, skip it
    for i in range(1, len(principle_sections), 2):
        if i + 1 < len(principle_sections):
            principle_id = principle_sections[i]
            principle_content = principle_sections[i + 1]
            
            # Extract title (first line after ID)
            lines = principle_content.strip().split('\n')
            title = lines[0].strip(' —').strip() if lines else principle_id
            
            # Clean up the content
            content_text = '\n'.join(lines[1:]).strip()
            
            principles.append({
                'principle_id': principle_id,
                'title': title,
                'content': content_text,
                'category': extract_category(principle_id, file_path)
            })
    
    return principles

def extract_all_principles(content: str, file_path: str) -> list:
    """Extract all principles - fallback method"""
    principles = []
    
    # Split by ### headers
    sections = re.split(r'\n### ', content)
    
    for section in sections[1:]:  # Skip first section (header)
        lines = section.strip().split('\n')
        if not lines:
            continue
            
        # Extract principle ID and title from first line
        first_line = lines[0]
        match = re.match(r'([A-Z]+-\d+)\s*—\s*(.+)', first_line)
        if match:
            principle_id = match.group(1)
            title = match.group(2)
            content_text = '\n'.join(lines[1:]).strip()
            
            principles.append({
                'principle_id': principle_id,
                'title': title,
                'content': content_text,
                'category': extract_category(principle_id, file_path)
            })
    
    return principles

def extract_category(principle_id: str, file_path: str) -> str:
    """Extract category from principle ID or file path"""
    file_name = Path(file_path).stem.lower()
    
    # Map file names to categories
    file_to_category = {
        'ea-principles': 'general',
        'ea-standards': 'standards',
        'integration-principles': 'integration',
        'architecture-review-taxonomy': 'taxonomy'
    }
    
    # Extract from principle ID prefix
    if principle_id.startswith('G-'):
        return 'general'
    elif principle_id.startswith('B-'):
        return 'business'
    elif principle_id.startswith('S-'):
        return 'security'
    elif principle_id.startswith('A-'):
        return 'application'
    elif principle_id.startswith('SW-'):
        return 'software'
    elif principle_id.startswith('D-'):
        return 'data'
    elif principle_id.startswith('I-'):
        return 'infrastructure'
    else:
        return file_to_category.get(file_name, 'general')

def extract_standards_from_md(content: str, file_path: str) -> list:
    """Extract standards from markdown content"""
    standards = []
    
    # Split by standard headers (### STANDARD-ID)
    standard_sections = re.split(r'\n### ([A-Z]+-\d+)', content)
    
    # First element is before first standard, skip it
    for i in range(1, len(standard_sections), 2):
        if i + 1 < len(standard_sections):
            standard_id = standard_sections[i]
            standard_content = standard_sections[i + 1]
            
            # Extract title
            lines = standard_content.strip().split('\n')
            title = lines[0].strip(' —').strip() if lines else standard_id
            
            # Clean up the content
            content_text = '\n'.join(lines[1:]).strip()
            
            standards.append({
                'principle_id': standard_id,  # Using same field for standards
                'title': title,
                'content': content_text,
                'category': 'standards'
            })
    
    return standards

def process_file(file_path: str, db: Session):
    """Process a single markdown file"""
    print(f"Processing: {file_path}")
    
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    file_name = Path(file_path).stem.lower()
    entries = []
    
    if file_name == 'ea-principles.md':
        entries = extract_all_principles(content, file_path)
    elif file_name == 'ea-standards.md':
        entries = extract_standards_from_md(content, file_path)
    elif file_name == 'integration-principles.md':
        entries = extract_all_principles(content, file_path)
    else:
        # For other files, create a single entry
        entries = [{
            'principle_id': None,
            'title': Path(file_path).stem.replace('-', ' ').title(),
            'content': content,
            'category': file_name.replace('-', '_')
        }]
    
    # Insert into database
    for entry in entries:
        kb_entry = KnowledgeBase(
            title=entry['title'],
            content=entry['content'],
            category=entry['category'],
            principle_id=entry['principle_id']
        )
        
        # Check if already exists
        existing = db.query(KnowledgeBase).filter(
            KnowledgeBase.principle_id == entry['principle_id'],
            KnowledgeBase.title == entry['title']
        ).first()
        
        if existing:
            print(f"  Updating existing: {entry['title']}")
            existing.content = entry['content']
            existing.category = entry['category']
        else:
            print(f"  Adding new: {entry['title']}")
            db.add(kb_entry)
    
    db.commit()
    print(f"  Processed {len(entries)} entries")

def main():
    """Main function to populate knowledge base"""
    print("Populating knowledge_base table from markdown files...")
    
    # Get database session
    db = SessionLocal()
    
    try:
        # Knowledge base directory
        kb_dir = Path("/Users/vijaykumardixit/CascadeProjects/ARB-AI-Agent/knowledge-base")
        
        # Process all markdown files
        md_files = list(kb_dir.glob("*.md"))
        
        if not md_files:
            print("No markdown files found in knowledge-base directory")
            return
        
        print(f"Found {len(md_files)} markdown files")
        
        for file_path in md_files:
            try:
                process_file(str(file_path), db)
            except Exception as e:
                print(f"Error processing {file_path}: {e}")
                continue
        
        # Print summary
        total_entries = db.query(KnowledgeBase).count()
        print(f"\nKnowledge base populated successfully!")
        print(f"Total entries: {total_entries}")
        
        # Show category breakdown
        categories = db.query(KnowledgeBase.category).distinct().all()
        for cat in categories:
            count = db.query(KnowledgeBase).filter(KnowledgeBase.category == cat[0]).count()
            print(f"  {cat[0]}: {count} entries")
        
    except Exception as e:
        print(f"Error: {e}")
        db.rollback()
    finally:
        db.close()

if __name__ == "__main__":
    main()
