from datetime import datetime

from sqlalchemy import DateTime, ForeignKey, Integer, Numeric, String, func
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.core.database import Base


class Deal(Base):
    __tablename__ = "deal"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    merchant_id: Mapped[int] = mapped_column(Integer, ForeignKey("merchant.id"), nullable=False)
    title: Mapped[str] = mapped_column(String(256), nullable=False)
    original_price: Mapped[float] = mapped_column(Numeric(10, 2), nullable=False)
    deal_price: Mapped[float] = mapped_column(Numeric(10, 2), nullable=False)
    sold_count: Mapped[int] = mapped_column(Integer, default=0, nullable=False)
    created_at: Mapped[datetime] = mapped_column(DateTime, server_default=func.now())

    merchant: Mapped["Merchant"] = relationship("Merchant", back_populates="deals")
    orders: Mapped[list["Order"]] = relationship("Order", back_populates="deal")
