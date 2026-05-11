import { useCallback, useEffect, useState } from "react";
import { useNavigate } from "react-router-dom";
import {
  Card,
  Col,
  Empty,
  Input,
  Pagination,
  Rate,
  Row,
  Select,
  Spin,
} from "antd";
import { getMerchants } from "../services/merchants";

const CATEGORIES = [
  "全部", "火锅", "日料", "川菜", "咖啡", "烧烤", "粤菜", "西餐", "甜品", "小吃", "其他",
];

const CITIES = ["全部", "北京", "上海", "广州", "深圳", "杭州", "成都", "武汉", "南京"];

function MerchantList() {
  const navigate = useNavigate();
  const [merchants, setMerchants] = useState([]);
  const [loading, setLoading] = useState(false);
  const [total, setTotal] = useState(0);
  const [filters, setFilters] = useState({
    page: 1,
    size: 12,
    category: "全部",
    city: "全部",
    keyword: "",
  });

  const fetchData = useCallback(() => {
    setLoading(true);
    const params = {
      page: filters.page,
      size: filters.size,
    };
    if (filters.category !== "全部") params.category = filters.category;
    if (filters.city !== "全部") params.city = filters.city;
    if (filters.keyword) params.keyword = filters.keyword;

    getMerchants(params)
      .then((res) => {
        setMerchants(res.data.data.items);
        setTotal(res.data.data.total);
      })
      .finally(() => setLoading(false));
  }, [filters]);

  useEffect(() => {
    fetchData();
  }, [fetchData]);

  const handleFilterChange = (key, value) => {
    setFilters((prev) => ({ ...prev, [key]: value, page: 1 }));
  };

  return (
    <div>
      {/* 筛选栏 */}
      <Row gutter={[16, 16]} style={{ marginBottom: 24 }}>
        <Col>
          <Select
            value={filters.category}
            onChange={(v) => handleFilterChange("category", v)}
            options={CATEGORIES.map((c) => ({ value: c, label: c }))}
            style={{ width: 120 }}
          />
        </Col>
        <Col>
          <Select
            value={filters.city}
            onChange={(v) => handleFilterChange("city", v)}
            options={CITIES.map((c) => ({ value: c, label: c }))}
            style={{ width: 120 }}
          />
        </Col>
        <Col>
          <Input.Search
            placeholder="搜索商家名称"
            value={filters.keyword}
            onChange={(e) => handleFilterChange("keyword", e.target.value)}
            onSearch={() => fetchData()}
            style={{ width: 240 }}
            allowClear
          />
        </Col>
      </Row>

      {/* 商家列表 */}
      <Spin spinning={loading}>
        {merchants.length === 0 && !loading ? (
          <Empty description="暂无商家" />
        ) : (
          <Row gutter={[16, 16]}>
            {merchants.map((m) => (
              <Col key={m.id} xs={24} sm={12} md={8} lg={6}>
                <Card
                  hoverable
                  onClick={() => navigate(`/merchant/${m.id}`)}
                  cover={
                    <div
                      style={{
                        height: 180,
                        background: m.image
                          ? `url(${m.image}) center/cover no-repeat`
                          : "#f0f0f0",
                        display: m.image ? "block" : "flex",
                        alignItems: "center",
                        justifyContent: "center",
                        color: "#bfbfbf",
                        fontSize: 48,
                      }}
                    >
                      {!m.image && "🍽️"}
                    </div>
                  }
                >
                  <Card.Meta
                    title={m.name}
                    description={
                      <div>
                        <div style={{ marginBottom: 8 }}>
                          <span style={{ color: "#8c8c8c" }}>{m.category}</span>
                        </div>
                        <Rate
                          value={m.rating}
                          allowHalf
                          disabled
                          style={{ fontSize: 14 }}
                        />
                        <span style={{ marginLeft: 8, color: "#faad14" }}>
                          {m.rating}
                        </span>
                        {m.avg_price && (
                          <div style={{ marginTop: 4, color: "#8c8c8c" }}>
                            💰 ¥{m.avg_price}/人
                          </div>
                        )}
                      </div>
                    }
                  />
                </Card>
              </Col>
            ))}
          </Row>
        )}
      </Spin>

      {/* 分页器 */}
      {total > 0 && (
        <div style={{ textAlign: "center", marginTop: 24 }}>
          <Pagination
            current={filters.page}
            pageSize={filters.size}
            total={total}
            showSizeChanger
            showQuickJumper
            showTotal={(t) => `共 ${t} 个商家`}
            pageSizeOptions={["8", "12", "20", "40"]}
            onChange={(page, size) => {
              if (size !== filters.size) {
                setFilters((prev) => ({ ...prev, page: 1, size }));
              } else {
                setFilters((prev) => ({ ...prev, page }));
              }
            }}
          />
        </div>
      )}
    </div>
  );
}

export default MerchantList;
