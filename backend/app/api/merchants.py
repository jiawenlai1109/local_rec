from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy import func, select
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.models.merchant import Merchant
from app.schemas.merchant import MerchantOut

router = APIRouter(tags=["merchants"])


@router.get("/merchants")
def list_merchants(
    page: int = Query(1, ge=1),
    size: int = Query(10, ge=1, le=100),
    category: str | None = Query(None),
    city: str | None = Query(None),
    keyword: str | None = Query(None),
    db: Session = Depends(get_db),
) -> dict:
    stmt = select(Merchant)
    count_stmt = select(func.count(Merchant.id))

    if category:
        stmt = stmt.where(Merchant.category == category)
        count_stmt = count_stmt.where(Merchant.category == category)
    if city:
        stmt = stmt.where(Merchant.city == city)
        count_stmt = count_stmt.where(Merchant.city == city)
    if keyword:
        stmt = stmt.where(Merchant.name.contains(keyword))
        count_stmt = count_stmt.where(Merchant.name.contains(keyword))

    total = db.execute(count_stmt).scalar_one()

    stmt = stmt.order_by(Merchant.rating.desc()).offset((page - 1) * size).limit(size)
    merchants = db.execute(stmt).scalars().all()

    return {
        "code": 0,
        "message": "ok",
        "data": {
            "items": [MerchantOut.model_validate(m).model_dump() for m in merchants],
            "total": total,
        },
    }


@router.get("/merchants/{merchant_id}")
def get_merchant(merchant_id: int, db: Session = Depends(get_db)) -> dict:
    merchant = db.get(Merchant, merchant_id)
    if not merchant:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="商家不存在")
    return {
        "code": 0,
        "message": "ok",
        "data": MerchantOut.model_validate(merchant).model_dump(),
    }
