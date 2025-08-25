"""Authentication Module for LMS Platform.

This module handles all aspects of user authentication including:
- Password hashing and verification
- JWT token generation and validation
- User authentication logic
- Dependency injection for database and current user
"""

from passlib.context import CryptContext
from jose import jwt, JWTError
from datetime import datetime, timedelta
from fastapi import Depends, HTTPException
from schemas import RegisterRequest
from fastapi.security import OAuth2PasswordBearer
from sqlalchemy.orm import Session
from typing import Optional
import os
from fastapi.responses import JSONResponse
from db import AuthUser, SessionLocal

from fastapi import APIRouter

router = APIRouter()

SECRET_KEY = os.getenv("SECRET_KEY")
ALGORITHM = os.getenv("ALGORITHM", "HS256")
ACCESS_TOKEN_EXPIRE_MINUTES = int(os.getenv("ACCESS_TOKEN_EXPIRE_MINUTES", 60))

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="token")

def get_db():
    """Create and yield a database session.
    
    This function serves as a FastAPI dependency for database access.
    It ensures the database session is properly closed after use.
    
    Yields:
        Session: A SQLAlchemy database session
    """
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

def get_password_hash(password: str) -> str:
    """Hash a password using bcrypt.
    
    Args:
        password: The plain text password to hash
        
    Returns:
        str: The hashed password
    """
    return pwd_context.hash(password)

@router.post("/register")
def register_user(request: RegisterRequest, db: Session = Depends(get_db)):
    # Check if user already exists
    existing_user = db.query(AuthUser).filter(AuthUser.username == request.username).first()
    if existing_user:
        raise HTTPException(status_code=409, detail="Username already exists")

    hashed = get_password_hash(request.password)
    new_user = AuthUser(username=request.username, hashed_password=hashed)
    db.add(new_user)
    db.commit()
    db.refresh(new_user)

    return JSONResponse(content={
        "status": "success",
        "user_id": new_user.userId,
        "username": new_user.username,
        "message": "User registered successfully"
    })


def verify_password(plain: str, hashed: str) -> bool:
    """Verify a password against a hash.
    
    Args:
        plain: The plain text password
        hashed: The hashed password to compare against
        
    Returns:
        bool: True if password matches, False otherwise
    """
    return pwd_context.verify(plain, hashed)

@router.post("/manual-login")
def manual_login(request: RegisterRequest, db: Session = Depends(get_db)):
    user = authenticate_user(db, request.username, request.password)
    if not user:
        raise HTTPException(status_code=401, detail="Invalid username or password")

    access_token = create_access_token(data={"sub": user.username})

    return JSONResponse(content={
        "status": "success",
        "user_id": user.userId,
        "username": user.username,
        "token": access_token,
        "message": "Logged in successfully"
    })

def create_access_token(data: dict, expires_delta: Optional[timedelta] = None) -> str:
    to_encode = data.copy()
    if isinstance(expires_delta, int):
        expires_delta = timedelta(minutes=expires_delta)
    expire = datetime.utcnow() + (expires_delta or timedelta(minutes=15))
    to_encode.update({"exp": expire})
    return jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)


def authenticate_user(db: Session, username: str, password: str) -> Optional[AuthUser]:
    """Authenticate a user with username and password.
    
    Args:
        db: Database session
        username: The username to authenticate
        password: The password to verify
        
    Returns:
        Optional[User]: The authenticated user object or None if authentication fails
    """
    user = db.query(AuthUser).filter(AuthUser.username == username).first()
    if not user or not verify_password(password, user.hashed_password):
        return None
    return user

async def get_current_user(token: str = Depends(oauth2_scheme), db: Session = Depends(get_db)) -> AuthUser:
    """Get the current authenticated user from a JWT token.
    
    This function is used as a FastAPI dependency to inject the current user
    into route handlers that require authentication.
    
    Args:
        token: The JWT token from the Authorization header
        db: Database session
        
    Returns:
        User: The authenticated user object
        
    Raises:
        HTTPException: 401 error if token is invalid or user doesn't exist
    """
    credentials_exception = HTTPException(status_code=401, detail="Invalid credentials")
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        username = payload.get("sub")
        if username is None:
            raise credentials_exception
    except JWTError:
        raise credentials_exception
    
    user = db.query(AuthUser).filter(AuthUser.username == username).first()
    if user is None:
        raise credentials_exception
    return user
