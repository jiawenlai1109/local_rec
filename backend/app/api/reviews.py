from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import func, select
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.dependencies import get_current_user
from app.models.merchant import Merchant
from app.models.review import Review
from app.models.user import User
from app.schemas.review import ReviewCreate, ReviewOut

router = APIRouter(tags=["reviews"])


@router.get("/merchants/{merchant_id}/reviews")
def list_reviews(merchant_id: int, db: Session = Depends(get_db)) -> dict:
    merchant = db.get(Merchant, merchant_id)
    if not merchant:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="商家不存在")

    reviews = db.execute(
        select(Review, User.username)
        .join(User, Review.user_id == User.id)
        .where(Review.merchant_id == merchant_id)
        .order_by(Review.created_at.desc())
    ).all()

    items = [
        ReviewOut.model_validate(r).model_dump() | {"username": username}
        for r, username in reviews
    ]
    return {"code": 0, "message": "ok", "data": items}


@router.post("/reviews")
def create_review(
    data: ReviewCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> dict:
    merchant = db.get(Merchant, data.merchant_id)
    if not merchant:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="商家不存在")

    existing = db.execute(
        select(Review).where(
            Review.user_id == current_user.id,
            Review.merchant_id == data.merchant_id,
        )
    ).scalar_one_or_none()
    if existing:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="您已对该商家发表过点评")

    review = Review(
        user_id=current_user.id,
        merchant_id=data.merchant_id,
        content=data.content,
        rating=data.rating,
    )
    db.add(review)
    db.flush()

    avg_result = db.execute(
        select(func.avg(Review.rating)).where(Review.merchant_id == data.merchant_id)
    ).scalar_one()
    merchant.rating = round(float(avg_result or 0), 1)

    db.commit()
    db.refresh(review)
    return {"code": 0, "message": "点评成功", "data": ReviewOut.model_validate(review).model_dump()}
