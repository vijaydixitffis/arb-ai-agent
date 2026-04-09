# ARB AI Agent - Architecture Review Board Automation

An AI-powered Architecture Review Board (ARB) system that automates the review process using RAG-based knowledge base validation, with human-in-the-loop oversight by Enterprise Architects.

## Architecture Overview

The system consists of:
- **Solution Architect Portal**: 8-step artefact submission form with checklist validation
- **Enterprise Architect Portal**: Human-in-the-loop review of AI-generated findings
- **AI Agent Pipeline**: Multi-agent system using LangChain/LangGraph for domain-specific validation
- **RAG Knowledge Base**: ChromaDB vector store with EA standards, principles, and patterns
- **ADR Generation**: Automated Architecture Decision Records creation

## Tech Stack

- **Frontend**: React 18 + TypeScript + TailwindCSS + shadcn/ui
- **Backend**: FastAPI (Python 3.11+)
- **AI Framework**: LangChain + LangGraph
- **Vector Store**: ChromaDB (local)
- **LLM**: OpenAI GPT-4 (configurable)
- **Authentication**: JWT-based role-based access (demo credentials)

## Project Structure

```
ARB-AI-Agent/
├── frontend/                 # React + TypeScript frontend
│   ├── src/
│   │   ├── components/      # Reusable components
│   │   ├── pages/           # Page components
│   │   ├── services/        # API services
│   │   ├── types/           # TypeScript types
│   │   └── utils/           # Utility functions
│   ├── package.json
│   └── tailwind.config.js
├── backend/                  # FastAPI backend
│   ├── app/
│   │   ├── api/             # API routes
│   │   ├── agents/          # LangChain agents
│   │   ├── core/            # Core functionality
│   │   ├── models/          # Database models
│   │   ├── services/        # Business logic
│   │   └── vector_store/    # ChromaDB setup
│   ├── requirements.txt
│   └── main.py
├── knowledge-base/          # EA standards and documents
│   ├── principles/
│   ├── patterns/
│   ├── standards/
│   └── adrs/
└── input-docs/              # Reference documents
```

## Demo Credentials

| Role | Email | Password |
|------|-------|----------|
| Solution Architect | sa@arb.demo | demo1234 |
| Enterprise Architect | ea@arb.demo | demo1234 |
| ARB Admin | admin@arb.demo | demo1234 |

## Quick Start

### Prerequisites
- Node.js 18+
- Python 3.11+
- OpenAI API key

### Backend Setup

```bash
cd backend
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
pip install -r requirements.txt
# Set environment variables
export OPENAI_API_KEY=your_openai_key
uvicorn main:app --reload --port 8000
```

### Frontend Setup

```bash
cd frontend
npm install
npm run dev
```

The application will be available at:
- Frontend: http://localhost:3000
- Backend API: http://localhost:8000
- API Docs: http://localhost:8000/docs

## ARB Submission Process

The 8-step ARB submission form includes:
1. **Solution Context**: Project overview, stakeholders, business drivers
2. **Application Architecture**: Tech stack, patterns, resilience
3. **Integration Architecture**: API design, event schemas, integration catalogue
4. **Data Architecture**: Classification, lifecycle, model documentation
5. **Security Architecture**: AuthN/AuthZ, RBAC, compliance
6. **Infrastructure Architecture**: Environments, platform, capacity
7. **DevSecOps**: CI/CD, quality gates, deployment strategy
8. **NFR Assessment**: Performance, HA/DR, security NFRs

Each section includes:
- Checklist items with options: Compliant / Non-Compliant / Partial / N/A
- Evidence notes field per checklist item
- Artefact upload with system-generated labels
- Progress indicator

## AI Agent Pipeline

The AI agent performs:
1. **Document Parsing**: Extracts text and structure from uploaded artefacts
2. **RAG Retrieval**: Queries EA knowledge base for relevant standards
3. **Domain Validation**: 6 specialist agents validate against domain-specific checklists
4. **NFR Assessment**: Scores non-functional requirements (1-5 scale)
5. **Decision Synthesis**: Aggregates scores and generates decision
6. **ADR Generation**: Creates architecture decision records
7. **Human Review**: EA reviews and approves/overrides findings

## Decision Taxonomy

- **APPROVE**: Meets all standards & NFRs; minor actions tracked
- **APPROVE w/ ACTIONS**: Conditions & timelines; post-ARB validations required
- **DEFER**: Gaps identified; return with updates by target date
- **REJECT**: Misaligned, unsafe or unviable; rework required

## Development Status

- [x] Architecture design
- [ ] Project scaffolding
- [ ] EA Knowledge Base setup
- [ ] AI Agent implementation
- [ ] Solution Architect portal
- [ ] Enterprise Architect portal
- [ ] ADR generation
- [ ] Frontend-backend integration
- [ ] Documentation

## License

Internal Enterprise Architecture Tool
