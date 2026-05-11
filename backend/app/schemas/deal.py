from datetime import datetime

from pydantic import BaseModel, ConfigDict


class DealBase(BaseModel):
    title: str
    original_price: float
    deal_price: float


class DealCreate(DealBase):
    merchant_id: int


class DealOut(DealBase):
    model_config = ConfigDict(from_attributes=True)

    id: int
    merchant_id: int
    sold_count: int
    created_at: datetime
