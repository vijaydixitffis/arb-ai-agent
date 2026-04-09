from fastapi import APIRouter
from app.api.endpoints import auth, arb_submissions, reviews, agent

api_router = APIRouter()

api_router.include_router(auth.router, prefix="/auth", tags=["authentication"])
api_router.include_router(arb_submissions.router, prefix="/submissions", tags=["submissions"])
api_router.include_router(reviews.router, prefix="/reviews", tags=["reviews"])
api_router.include_router(agent.router, prefix="/agent", tags=["agent"])
