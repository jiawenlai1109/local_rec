from datetime import datetime

from pydantic import BaseModel, ConfigDict


class ReviewBase(BaseModel):
    content: str
    rating: int


class ReviewCreate(ReviewBase):
    merchant_id: int


class ReviewOut(ReviewBase):
    model_config = ConfigDict(from_attributes=True)

    id: int
    user_id: int
    merchant_id: int
    created_at: datetime
