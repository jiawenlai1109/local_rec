from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.dependencies import get_current_user
from app.core.security import create_access_token, hash_password, verify_password
from app.models.user import User
from app.schemas.user import TokenOut, UserCreate, UserLogin, UserOut

router = APIRouter(tags=["users"])


@router.post("/register")
def register(data: UserCreate, db: Session = Depends(get_db)) -> dict:
    existing = db.execute(
        select(User).where(User.username == data.username)
    ).scalar_one_or_none()
    if existing:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="用户名已存在")

    user = User(username=data.username, password_hash=hash_password(data.password))
    db.add(user)
    db.commit()
    db.refresh(user)
    return {"code": 0, "message": "注册成功", "data": None}


@router.post("/login")
def login(data: UserLogin, db: Session = Depends(get_db)) -> dict:
    user = db.execute(
        select(User).where(User.username == data.username)
    ).scalar_one_or_none()
    if not user or not verify_password(data.password, user.password_hash):
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="用户名或密码错误")

    token = create_access_token({"sub": str(user.id)})
    return {"code": 0, "message": "ok", "data": TokenOut(access_token=token).model_dump()}


@router.delete("/users/me")
def delete_account(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> dict:
    for review in current_user.reviews:
        db.delete(review)
    for order in current_user.orders:
        db.delete(order)
    db.delete(current_user)
    db.commit()
    return {"code": 0, "message": "账号已注销", "data": None}
