import os
import random
import sys

sys.path.insert(0, os.path.dirname(__file__))

from sqlalchemy import func, select

from app.core.database import SessionLocal, engine
from app.models import Base
from app.models.deal import Deal
from app.models.merchant import Merchant
from app.models.order import Order
from app.models.review import Review
from app.models.user import User
from faker import Faker
from passlib.context import CryptContext

fake = Faker("zh_CN")
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")
hash_password = pwd_context.hash


def generate_restaurant_name(category):
    """生成符合类别的餐厅名"""
    style = random.random()
    if style < 0.5:
        # 前缀 + 后缀：老张火锅、蜀味川菜馆
        prefix = random.choice(NAME_PREFIXES).format(last=fake.last_name())
        suffix = random.choice(NAME_SUFFIXES_BY_CATEGORY[category])
        return f"{prefix}{suffix}"
    else:
        # 姓氏 + 记 + 后缀：赵记烤肉店、李记茶餐厅
        last = fake.last_name()
        suffix = random.choice(NAME_SUFFIXES_BY_CATEGORY[category])
        return f"{last}记{suffix}"


def generate_deal_title(category):
    """生成符合类别的团购标题"""
    return random.choice(DEAL_TITLES.get(category, DEAL_TITLES["其他"]))

CATEGORIES = ["火锅", "日料", "川菜", "咖啡", "烧烤", "粤菜", "西餐", "甜品", "小吃", "其他"]
CITIES = ["北京", "上海", "广州", "深圳", "杭州", "成都", "武汉", "南京"]

# 餐厅名称前缀（姓氏、地名、风格）
NAME_PREFIXES = [
    "老{last}", "{last}记", "{last}家", "{last}氏",
    "蜀味", "巴蜀", "锦城", "渝州", "蓉城",
    "樱庭", "和风", "富士", "浅草", "京都",
    "粤海", "岭南", "南国", "珠江",
    "阿里", "牧羊", "塞外", "草原",
    "海上", "弄堂", "老上海", "外滩",
    "胡同", "四合院", "皇城", "燕京",
    "湖畔", "山城", "江南", "长安",
    "香满楼", "翠华", "聚福", "鸿运", "金鼎",
]

# 餐厅名称后缀（按类别）
NAME_SUFFIXES_BY_CATEGORY = {
    "火锅": ["火锅", "火锅城", "涮涮锅", "老火锅", "打边炉"],
    "日料": ["日料", "日本料理", "居酒屋", "寿司店", "拉面馆"],
    "川菜": ["川菜馆", "川味馆", "麻辣馆", "串串香", "川菜酒楼"],
    "咖啡": ["咖啡", "咖啡馆", "咖啡屋", "Coffee", "咖啡书吧"],
    "烧烤": ["烧烤", "烤肉馆", "烤肉店", "BBQ", "烤吧"],
    "粤菜": ["粤菜馆", "茶餐厅", "烧腊店", "点心坊", "粤菜酒楼"],
    "西餐": ["西餐厅", "牛排馆", "意式餐厅", "法式餐厅", "西式简餐"],
    "甜品": ["甜品店", "糖水铺", "烘焙坊", "蛋糕店", "冰淇淋屋"],
    "小吃": ["小吃店", "面馆", "包子铺", "饺子馆", "米线店"],
    "其他": ["餐厅", "美食城", "食府", "酒家", "馆子", "小馆", "轩", "阁"],
}

# 团购标题模板
DEAL_TITLES = {
    "火锅": ["双人火锅套餐", "四人欢聚火锅宴", "招牌毛肚+鸭肠组合", "自助火锅畅吃", "鸳鸯锅底双人餐"],
    "日料": ["刺身拼盘豪华套餐", "双人寿司盛宴", "和牛寿喜锅双人餐", "日式拉面套餐", "天妇罗定食"],
    "川菜": ["招牌水煮鱼套餐", "麻辣香锅双人餐", "夫妻肺片+口水鸡组合", "宫保鸡丁盖饭", "川味经典三人餐"],
    "咖啡": ["精品手冲体验", "拿铁+甜品下午茶", "双人咖啡套餐", "冷萃咖啡月卡", "咖啡豆礼盒装"],
    "烧烤": ["羊肉串 20 串畅享", "双人韩式烤肉套餐", "烤全翅 6 只装", "海鲜烧烤拼盘", "和牛烤肉套餐"],
    "粤菜": ["广式早茶点心畅吃", "烧鹅双拼饭", "煲仔饭套餐", "双皮奶+杨枝甘露", "白切鸡半只套餐"],
    "西餐": ["澳洲牛排双人餐", "意面+沙拉轻食套餐", "披萨双人欢享餐", "法式焗蜗牛体验", "汉堡薯条套餐"],
    "甜品": ["招牌蛋糕 6 寸", "下午茶甜点双人餐", "手工冰淇淋三球", "蛋挞一打装", "提拉米苏+咖啡"],
    "小吃": ["招牌小面+卤蛋", "灌汤包一笼", "煎饼果子套餐", "肉夹馍+凉皮", "鸭血粉丝汤套餐"],
    "其他": ["超值双人餐", "招牌单人套餐", "家庭三人欢享餐", "豪华四人套餐", "尝鲜体验套餐"],
}

HOURS_TEMPLATES = [
    "周一至周日 10:00-22:00",
    "周一至周日 09:00-21:00",
    "周一至周五 10:00-22:00，周末 09:00-23:00",
    "周一至周日 11:00-00:00",
    "周一至周日 08:00-20:00",
]


def main():
    Base.metadata.create_all(bind=engine)
    db = SessionLocal()

    try:
        # 1. 清空数据（按外键依赖倒序）
        db.execute(Order.__table__.delete())
        db.execute(Review.__table__.delete())
        db.execute(Deal.__table__.delete())
        db.execute(Merchant.__table__.delete())
        db.execute(User.__table__.delete())
        db.commit()

        # 2. 创建用户
        users = [
            User(username="tester", password_hash=hash_password("pass123")),
            User(username="user2", password_hash=hash_password("pass123")),
            User(username="user3", password_hash=hash_password("pass123")),
            User(username="user4", password_hash=hash_password("pass123")),
        ]
        db.add_all(users)
        db.flush()

        # 3. 创建 50 个商家
        merchants = []
        for _ in range(50):
            category = random.choice(CATEGORIES)
            m = Merchant(
                name=generate_restaurant_name(category),
                image=f"https://picsum.photos/400/300?random={random.randint(1, 1000)}",
                rating=round(random.uniform(3.0, 5.0), 1),
                avg_price=random.choice([30, 40, 50, 60, 80, 100, 120, 150, 200, 300]),
                category=category,
                city=random.choice(CITIES),
                address=fake.address(),
                phone=fake.phone_number(),
                hours_desc=random.choice(HOURS_TEMPLATES),
            )
            merchants.append(m)
        db.add_all(merchants)
        db.flush()

        # 4. 每个商家生成 2-3 个团购商品
        deals = []
        for m in merchants:
            num_deals = random.randint(2, 3)
            for _ in range(num_deals):
                original_price = round(random.uniform(50, 500), 2)
                d = Deal(
                    merchant_id=m.id,
                    title=generate_deal_title(m.category),
                    original_price=original_price,
                    deal_price=round(original_price * random.uniform(0.5, 0.9), 2),
                    sold_count=random.randint(0, 100),
                )
                deals.append(d)
        db.add_all(deals)
        db.flush()

        # 5. 每个商家生成 5-10 条点评
        reviews = []
        for m in merchants:
            num_reviews = min(random.randint(3, len(users)), len(users))
            reviewers = random.sample(users, num_reviews)
            for reviewer in reviewers:
                r = Review(
                    user_id=reviewer.id,
                    merchant_id=m.id,
                    content=fake.paragraph(),
                    rating=random.randint(1, 5),
                )
                reviews.append(r)
        db.add_all(reviews)
        db.flush()

        # 6. 更新商家平均评分
        for m in merchants:
            avg_result = db.execute(
                select(func.avg(Review.rating)).where(Review.merchant_id == m.id)
            ).scalar_one()
            m.rating = round(float(avg_result), 1)

        # 7. 生成少量订单（tester 购买前 3 个团购）
        test_user = users[0]
        sample_deals = deals[:3]
        orders = [
            Order(user_id=test_user.id, deal_id=d.id) for d in sample_deals
        ]
        db.add_all(orders)

        db.commit()

        # 统计
        user_count = db.execute(select(func.count(User.id))).scalar_one()
        merchant_count = db.execute(select(func.count(Merchant.id))).scalar_one()
        deal_count = db.execute(select(func.count(Deal.id))).scalar_one()
        review_count = db.execute(select(func.count(Review.id))).scalar_one()
        order_count = db.execute(select(func.count(Order.id))).scalar_one()

        print(f"数据填充完成！")
        print(f"  用户: {user_count}")
        print(f"  商家: {merchant_count}")
        print(f"  团购: {deal_count}")
        print(f"  点评: {review_count}")
        print(f"  订单: {order_count}")

    finally:
        db.close()


if __name__ == "__main__":
    main()
