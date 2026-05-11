from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.api.deals import router as deals_router
from app.api.merchants import router as merchants_router
from app.api.reviews import router as reviews_router
from app.api.users import router as users_router
from app.core.database import Base, engine


@asynccontextmanager
async def lifespan(app: FastAPI):
    Base.metadata.create_all(bind=engine)
    yield


app = FastAPI(title="本地推荐系统", lifespan=lifespan)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://localhost:3000"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(users_router, prefix="/api")
app.include_router(merchants_router, prefix="/api")
app.include_router(reviews_router, prefix="/api")
app.include_router(deals_router, prefix="/api")


@app.get("/")
def root():
    return {"code": 0, "message": "ok", "data": None}
