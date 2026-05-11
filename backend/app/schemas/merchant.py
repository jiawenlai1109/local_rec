from datetime import datetime

from pydantic import BaseModel, ConfigDict


class MerchantBase(BaseModel):
    name: str
    image: str | None = None
    avg_price: int | None = None
    category: str
    city: str
    address: str | None = None
    phone: str | None = None
    hours_desc: str | None = None


class MerchantCreate(MerchantBase):
    pass


class MerchantOut(MerchantBase):
    model_config = ConfigDict(from_attributes=True)

    id: int
    rating: float
    created_at: datetime
