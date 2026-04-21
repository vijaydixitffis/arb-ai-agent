from sqlalchemy import Column, String, Integer, Boolean, DateTime, Text, ARRAY, Date
from sqlalchemy.dialects.postgresql import UUID, JSONB
from sqlalchemy.orm import relationship
from app.core.database import Base
import uuid
from datetime import datetime

class Review(Base):
    __tablename__ = "reviews"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    created_at = Column(DateTime(timezone=True), default=datetime.utcnow, nullable=False)
    submitted_at = Column(DateTime(timezone=True), nullable=True)
    reviewed_at = Column(DateTime(timezone=True), nullable=True)
    
    sa_user_id = Column(UUID(as_uuid=True), nullable=True)
    solution_name = Column(String, nullable=False)
    scope_tags = Column(ARRAY(String), nullable=False)
    artifact_path = Column(String, nullable=False)
    artifact_filename = Column(String, nullable=False)
    artifact_file_type = Column(String, nullable=True)
    artifact_file_size_bytes = Column(Integer, nullable=True)
    
    status = Column(String, nullable=False, default='pending')
    decision = Column(String, nullable=True)
    
    llm_model = Column(String, default='gpt-4o')
    tokens_used = Column(Integer, nullable=True)
    processing_time_ms = Column(Integer, nullable=True)
    llm_raw_response = Column(Text, nullable=True)
    
    ea_user_id = Column(UUID(as_uuid=True), nullable=True)
    ea_override_notes = Column(Text, nullable=True)
    ea_overridden_at = Column(DateTime(timezone=True), nullable=True)
    
    report_json = Column(JSONB, nullable=True)

class DomainScore(Base):
    __tablename__ = "domain_scores"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    review_id = Column(UUID(as_uuid=True), nullable=False)
    domain = Column(String, nullable=False)
    score = Column(Integer, nullable=False)
    created_at = Column(DateTime(timezone=True), default=datetime.utcnow, nullable=False)

class Finding(Base):
    __tablename__ = "findings"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    review_id = Column(UUID(as_uuid=True), nullable=False)
    domain = Column(String, nullable=False)
    principle_id = Column(String, nullable=True)
    severity = Column(String, nullable=False)
    finding = Column(Text, nullable=False)
    recommendation = Column(Text, nullable=True)
    is_resolved = Column(Boolean, default=False)
    created_at = Column(DateTime(timezone=True), default=datetime.utcnow, nullable=False)

class ADR(Base):
    __tablename__ = "adrs"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    review_id = Column(UUID(as_uuid=True), nullable=False)
    adr_id = Column(String, nullable=False)
    decision = Column(String, nullable=False)
    rationale = Column(Text, nullable=False)
    context = Column(Text, nullable=True)
    consequences = Column(Text, nullable=True)
    owner = Column(String, nullable=True)
    target_date = Column(Date, nullable=True)
    status = Column(String, default='proposed')
    created_at = Column(DateTime(timezone=True), default=datetime.utcnow, nullable=False)
    updated_at = Column(DateTime(timezone=True), default=datetime.utcnow, nullable=False)

class Action(Base):
    __tablename__ = "actions"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    review_id = Column(UUID(as_uuid=True), nullable=False)
    action_text = Column(Text, nullable=False)
    status = Column(String, nullable=False)
    owner_role = Column(String, nullable=True)
    due_days = Column(Integer, nullable=True)
    due_date = Column(Date, nullable=True)
    created_at = Column(DateTime(timezone=True), default=datetime.utcnow, nullable=False)
