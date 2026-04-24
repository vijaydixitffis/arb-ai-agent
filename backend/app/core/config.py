from pydantic_settings import BaseSettings
from typing import Optional

class Settings(BaseSettings):
    # API Configuration
    API_V1_STR: str = "/api/v1"
    PROJECT_NAME: str = "ARB AI Agent"
    
    # OpenAI Configuration
    OPENAI_API_KEY: str
    OPENAI_MODEL: str = "gpt-4o"
    OPENAI_EMBEDDING_MODEL: str = "text-embedding-3-large"
    
    # Gemini Configuration
    GEMINI_API_KEY: str
    GEMINI_MODEL: str = "gemini-1.5-pro"
    GEMINI_EMBEDDING_MODEL: str = "text-embedding-004"
    
    # LLM Provider Selection
    LLM_PROVIDER: str = "openai"  # Options: "openai", "gemini"
    
    # Vector Store Configuration
    CHROMA_PERSIST_DIRECTORY: str = "./chroma_db"
    
    # JWT Configuration
    SECRET_KEY: str = "your-secret-key-change-in-production"
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 60 * 24 * 7  # 7 days
    
    # File Upload Configuration
    MAX_UPLOAD_SIZE: int = 50 * 1024 * 1024  # 50MB
    ALLOWED_FILE_TYPES: list = [
        "application/pdf",
        "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
        "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
        "image/png",
        "image/jpeg",
        "image/svg+xml"
    ]
    
    # Database Configuration
    DATABASE_URL: str = "postgresql://postgres:postgres@localhost:5432/arb_ai_agent"
    
    class Config:
        env_file = ".env"
        case_sensitive = True

settings = Settings()
