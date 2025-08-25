"""Pydantic Schemas Module for LMS Platform.

This module defines data models used for request validation and response
serialization throughout the application. All models extend from Pydantic's
BaseModel to provide automatic validation, serialization, and documentation.
"""

from pydantic import BaseModel, ConfigDict, Field
from typing import Optional

class RegisterRequest(BaseModel):
    """Schema for user registration request.
    
    Validates incoming registration requests, ensuring they contain
    the required username and password fields.
    """
    username: str
    """The desired username for the new account."""
    password: str
    """The password for the new account."""


class UserResponse(BaseModel):
    """Schema for returning user information.
    
    Excludes sensitive data like passwords.
    """
    userId: int
    """The unique identifier of the user."""
    username: str
    """The username of the user."""

    model_config = ConfigDict(from_attributes=True) #  Ensures compatibility with SQLAlchemy models
