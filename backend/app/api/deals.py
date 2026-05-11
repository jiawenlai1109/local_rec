from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy import func, select
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.dependencies import get_current_user
from app.models.deal import Deal
from app.models.merchant import Merchant
from app.models.order import Order
from app.models.user import User
from app.schemas.deal import DealOut
from app.schemas.order import OrderCreate, OrderOut

router = APIRouter(tags=["deals"])


@router.get("/merchants/{merchant_id}/deals")
def list_merchant_deals(merchant_id: int, db: Session = Depends(get_db)) -> dict:
    merchant = db.get(Merchant, merchant_id)
    if not merchant:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="商家不存在")

    deals = db.execute(
        select(Deal).where(Deal.merchant_id == merchant_id)
    ).scalars().all()
    return {
        "code": 0,
        "message": "ok",
        "data": [DealOut.model_validate(d).model_dump() for d in deals],
    }


@router.get("/deals")
def list_all_deals(
    page: int = Query(1, ge=1),
    size: int = Query(10, ge=1, le=100),
    db: Session = Depends(get_db),
) -> dict:
    count_stmt = select(func.count(Deal.id))
    total = db.execute(count_stmt).scalar_one()
    deals = db.execute(
        select(Deal)
        .order_by(Deal.sold_count.desc())
        .offset((page - 1) * size)
        .limit(size)
    ).scalars().all()
    return {
        "code": 0,
        "message": "ok",
        "data": {
            "items": [DealOut.model_validate(d).model_dump() for d in deals],
            "total": total,
        },
    }


@router.post("/orders")
def create_order(
    data: OrderCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> dict:
    deal = db.execute(
        select(Deal).where(Deal.id == data.deal_id).with_for_update()
    ).scalar_one_or_none()
    if not deal:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="团购商品不存在")

    order = Order(user_id=current_user.id, deal_id=data.deal_id)
    deal.sold_count += 1

    db.add(order)
    db.commit()
    db.refresh(order)
    return {
        "code": 0,
        "message": "购买成功",
        "data": OrderOut.model_validate(order).model_dump(),
    }


@router.get("/orders")
def list_my_orders(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> dict:
    rows = db.execute(
        select(Order, Deal, Merchant.name)
        .join(Deal, Order.deal_id == Deal.id)
        .join(Merchant, Deal.merchant_id == Merchant.id)
        .where(Order.user_id == current_user.id)
        .order_by(Order.created_at.desc())
    ).all()

    items = [
        OrderOut.model_validate(o).model_dump()
        | {
            "deal": DealOut.model_validate(d).model_dump(),
            "merchant_name": merchant_name,
        }
        for o, d, merchant_name in rows
    ]
    return {"code": 0, "message": "ok", "data": items}


@router.put("/orders/{order_id}/use")
def use_order(
    order_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> dict:
    order = db.execute(
        select(Order).where(Order.id == order_id).with_for_update()
    ).scalar_one_or_none()
    if not order:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="订单不存在")
    if order.user_id != current_user.id:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="无权操作此订单")
    if order.status != "待使用":
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="订单状态不允许使用")

    order.status = "已使用"
    db.commit()
    return {"code": 0, "message": "使用成功", "data": None}


@router.put("/orders/{order_id}/refund")
def refund_order(
    order_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> dict:
    order = db.execute(
        select(Order).where(Order.id == order_id).with_for_update()
    ).scalar_one_or_none()
    if not order:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="订单不存在")
    if order.user_id != current_user.id:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="无权操作此订单")
    if order.status != "待使用":
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="订单状态不允许退款")

    order.status = "已退款"
    deal = db.execute(
        select(Deal).where(Deal.id == order.deal_id).with_for_update()
    ).scalar_one_or_none()
    deal.sold_count = max(0, deal.sold_count - 1)
    db.commit()
    return {"code": 0, "message": "退款成功", "data": None}
