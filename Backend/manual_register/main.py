from fastapi import FastAPI, Request, Response
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from Username_pwd import router
import uvicorn
import os
from db import Base, engine
from contextlib import asynccontextmanager

@asynccontextmanager
async def lifespan(app: FastAPI):
    Base.metadata.create_all(bind=engine)
    yield

app = FastAPI(
    docs_url="/api-docs",
    lifespan=lifespan
)

port = int(os.environ.get("PORT", 8000))



# List of allowed origins
ALLOWED_ORIGINS = [
    "http://localhost:3000" ,
     "*" # Local development
]

# Enhanced CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=ALLOWED_ORIGINS,
    allow_origin_regex=r"https?://(localhost|.*\.yourdomain\.com|.*-yourusername\.vercel\.app)",  # Add regex patterns if needed
    allow_credentials=True,
    allow_methods=["GET", "POST", "PUT", "DELETE", "OPTIONS", "PATCH"],
    allow_headers=[
        "Content-Type",
        "Authorization",
        "Access-Control-Allow-Headers",
        "Access-Control-Allow-Origin",
        "X-Requested-With",
        "X-CSRF-Token",
        "Accept",
        "Accept-Version",
        "Content-Length",
        "Content-MD5",
        "Date",
        "X-Api-Version",
        "X-Request-Id",
        "X-Forwarded-For",
        "X-Forwarded-Proto",
        "X-Forwarded-Host",
        "X-Forwarded-Port",
        "X-Forwarded-Prefix",
    ],
    expose_headers=[
        "Content-Range",
        "X-Total-Count",
        "Link",
        "X-Request-Id",
        "X-Response-Time",
    ],
    max_age=600,  # 10 minutes
)

# Add a simple health check endpoint
@app.get("/health")
async def health_check():
    return {"status": "ok"}

# Include your router
app.include_router(router)


if __name__ == "__main__":
    dev = os.getenv("ENV") == "dev"
    uvicorn.run("main:app", host="0.0.0.0", port=port, reload=dev)
