from datetime import datetime

from sqlalchemy import DateTime, Float, Integer, String, Text, func
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.core.database import Base


class Merchant(Base):
    __tablename__ = "merchant"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    name: Mapped[str] = mapped_column(String(128), nullable=False)
    image: Mapped[str | None] = mapped_column(String(512))
    rating: Mapped[float] = mapped_column(Float, default=0.0, nullable=False)
    avg_price: Mapped[int | None] = mapped_column(Integer)
    category: Mapped[str] = mapped_column(String(32), nullable=False)
    city: Mapped[str] = mapped_column(String(32), nullable=False)
    address: Mapped[str | None] = mapped_column(String(256))
    phone: Mapped[str | None] = mapped_column(String(32))
    hours_desc: Mapped[str | None] = mapped_column(Text)
    created_at: Mapped[datetime] = mapped_column(DateTime, server_default=func.now())

    reviews: Mapped[list["Review"]] = relationship("Review", back_populates="merchant")
    deals: Mapped[list["Deal"]] = relationship("Deal", back_populates="merchant")
