from fastapi import APIRouter, HTTPException, Depends
from fastapi.security import OAuth2PasswordBearer, OAuth2PasswordRequestForm
from app.models.user import UserLogin, Token, DEMO_USERS
from app.core.security import verify_password, create_access_token

router = APIRouter()
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/api/v1/auth/login")

@router.post("/login", response_model=Token)
async def login(form_data: OAuth2PasswordRequestForm = Depends()):
    user = DEMO_USERS.get(form_data.username)
    if not user or not verify_password(form_data.password, user["hashed_password"]):
        raise HTTPException(status_code=401, detail="Invalid credentials")
    
    access_token = create_access_token(data={"sub": user["email"], "role": user["role"]})
    
    return Token(
        access_token=access_token,
        token_type="bearer",
        user={
            "id": user["id"],
            "email": user["email"],
            "name": user["name"],
            "role": user["role"]
        }
    )

@router.get("/demo-users")
async def get_demo_users():
    return {
        "users": [
            {"email": "sa@arb.demo", "password": "demo1234", "role": "Solution Architect"},
            {"email": "ea@arb.demo", "password": "demo1234", "role": "Enterprise Architect"},
            {"email": "admin@arb.demo", "password": "demo1234", "role": "ARB Admin"}
        ]
    }
