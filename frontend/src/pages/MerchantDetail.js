import { useCallback, useEffect, useState } from "react";
import { useParams } from "react-router-dom";
import {
  Button,
  Card,
  Descriptions,
  Form,
  Input,
  List,
  message,
  Rate,
  Spin,
  Tabs,
  Tag,
  Typography,
} from "antd";
import {
  EnvironmentOutlined,
  PhoneOutlined,
  ClockCircleOutlined,
} from "@ant-design/icons";
import { getMerchant } from "../services/merchants";
import { getReviews, createReview } from "../services/reviews";
import { getDealsByMerchant, createOrder } from "../services/deals";

const { Text, Title } = Typography;
const { TextArea } = Input;

function getUserIdFromToken() {
  const token = localStorage.getItem("access_token");
  if (!token) return null;
  try {
    return JSON.parse(atob(token.split(".")[1])).sub;
  } catch {
    return null;
  }
}

function MerchantDetail() {
  const { id } = useParams();
  const merchantId = parseInt(id);

  const [merchant, setMerchant] = useState(null);
  const [deals, setDeals] = useState([]);
  const [reviews, setReviews] = useState([]);
  const [loading, setLoading] = useState(true);
  const [buyingId, setBuyingId] = useState(null);
  const [submitting, setSubmitting] = useState(false);
  const [form] = Form.useForm();

  const isLoggedIn = !!localStorage.getItem("access_token");
  const currentUserId = getUserIdFromToken();
  const hasReviewed = reviews.some((r) => r.user_id === currentUserId);

  const fetchData = useCallback(() => {
    setLoading(true);
    Promise.all([
      getMerchant(merchantId),
      getDealsByMerchant(merchantId),
      getReviews(merchantId),
    ])
      .then(([mRes, dRes, rRes]) => {
        setMerchant(mRes.data.data);
        setDeals(dRes.data.data);
        setReviews(rRes.data.data);
      })
      .finally(() => setLoading(false));
  }, [merchantId]);

  useEffect(() => {
    fetchData();
  }, [fetchData]);

  const handleBuy = (dealId) => {
    setBuyingId(dealId);
    createOrder(dealId)
      .then(() => {
        message.success("购买成功");
        return getDealsByMerchant(merchantId);
      })
      .then((res) => setDeals(res.data.data))
      .catch((err) => message.error(err.response?.data?.detail || "购买失败"))
      .finally(() => setBuyingId(null));
  };

  const handleSubmitReview = (values) => {
    setSubmitting(true);
    createReview({
      merchant_id: merchantId,
      rating: values.rating,
      content: values.content,
    })
      .then(() => {
        message.success("点评成功");
        form.resetFields();
        return Promise.all([
          getMerchant(merchantId),
          getReviews(merchantId),
        ]);
      })
      .then(([mRes, rRes]) => {
        setMerchant(mRes.data.data);
        setReviews(rRes.data.data);
      })
      .catch((err) => message.error(err.response?.data?.detail || "点评失败"))
      .finally(() => setSubmitting(false));
  };

  if (loading) {
    return (
      <div style={{ textAlign: "center", padding: 80 }}>
        <Spin size="large" />
      </div>
    );
  }

  if (!merchant) {
    return <div style={{ textAlign: "center", padding: 80 }}>商家不存在</div>;
  }

  return (
    <div style={{ maxWidth: 960, margin: "0 auto" }}>
      {/* 商家基本信息 */}
      <Card style={{ marginBottom: 24 }}>
        <Title level={3} style={{ marginBottom: 4 }}>
          {merchant.name}
        </Title>
        <div style={{ marginBottom: 16 }}>
          <Tag color="blue">{merchant.category}</Tag>
          <Rate value={merchant.rating} allowHalf disabled style={{ fontSize: 16, marginLeft: 8 }} />
          <Text style={{ marginLeft: 8, fontSize: 18, color: "#faad14", fontWeight: "bold" }}>
            {merchant.rating}
          </Text>
          {merchant.avg_price && (
            <Text style={{ marginLeft: 16, color: "#8c8c8c" }}>
              💰 人均 ¥{merchant.avg_price}
            </Text>
          )}
        </div>
        <Descriptions column={1} size="small">
          {merchant.address && (
            <Descriptions.Item
              label={<><EnvironmentOutlined /> 地址</>}
            >
              {merchant.address}
            </Descriptions.Item>
          )}
          {merchant.phone && (
            <Descriptions.Item
              label={<><PhoneOutlined /> 电话</>}
            >
              {merchant.phone}
            </Descriptions.Item>
          )}
          {merchant.hours_desc && (
            <Descriptions.Item
              label={<><ClockCircleOutlined /> 营业时间</>}
            >
              {merchant.hours_desc}
            </Descriptions.Item>
          )}
        </Descriptions>
      </Card>

      {/* 标签页：团购 + 点评 */}
      <Tabs
        defaultActiveKey="deals"
        items={[
          {
            key: "deals",
            label: `团购商品 (${deals.length})`,
            children: (
              <div>
                {deals.length === 0 ? (
                  <div style={{ textAlign: "center", padding: 40, color: "#8c8c8c" }}>
                    暂无团购商品
                  </div>
                ) : (
                  <List
                    dataSource={deals}
                    renderItem={(deal) => (
                      <List.Item
                        actions={[
                          isLoggedIn && (
                            <Button
                              key="buy"
                              type="primary"
                              loading={buyingId === deal.id}
                              onClick={() => handleBuy(deal.id)}
                            >
                              立即购买
                            </Button>
                          ),
                        ].filter(Boolean)}
                      >
                        <List.Item.Meta
                          title={deal.title}
                          description={
                            <div>
                              <Text delete style={{ marginRight: 12 }}>
                                ¥{deal.original_price}
                              </Text>
                              <Text style={{ fontSize: 20, color: "#f5222d", fontWeight: "bold" }}>
                                ¥{deal.deal_price}
                              </Text>
                              <Text style={{ marginLeft: 16, color: "#8c8c8c" }}>
                                已售 {deal.sold_count}
                              </Text>
                            </div>
                          }
                        />
                      </List.Item>
                    )}
                  />
                )}
              </div>
            ),
          },
          {
            key: "reviews",
            label: `用户点评 (${reviews.length})`,
            children: (
              <div>
                {/* 点评表单 */}
                {isLoggedIn && !hasReviewed && (
                  <Card size="small" style={{ marginBottom: 24 }}>
                    <Form form={form} onFinish={handleSubmitReview}>
                      <Form.Item
                        name="rating"
                        rules={[{ required: true, message: "请评分" }]}
                      >
                        <Rate />
                      </Form.Item>
                      <Form.Item
                        name="content"
                        rules={[{ required: true, message: "请输入点评内容" }]}
                      >
                        <TextArea rows={3} placeholder="分享你的体验..." />
                      </Form.Item>
                      <Form.Item style={{ marginBottom: 0 }}>
                        <Button type="primary" htmlType="submit" loading={submitting}>
                          提交点评
                        </Button>
                      </Form.Item>
                    </Form>
                  </Card>
                )}

                {/* 已有点评列表 */}
                {reviews.length === 0 ? (
                  <div style={{ textAlign: "center", padding: 40, color: "#8c8c8c" }}>
                    暂无点评
                  </div>
                ) : (
                  <List
                    dataSource={reviews}
                    renderItem={(review) => (
                      <List.Item>
                        <List.Item.Meta
                          title={
                            <div>
                              <Text strong>{review.username || `用户${review.user_id}`}</Text>
                              <Rate
                                value={review.rating}
                                disabled
                                style={{ fontSize: 14, marginLeft: 12 }}
                              />
                            </div>
                          }
                          description={
                            <div>
                              <div style={{ marginBottom: 4, whiteSpace: "pre-wrap" }}>
                                {review.content}
                              </div>
                              <Text style={{ color: "#bfbfbf", fontSize: 12 }}>
                                {new Date(review.created_at).toLocaleString()}
                              </Text>
                            </div>
                          }
                        />
                      </List.Item>
                    )}
                  />
                )}
              </div>
            ),
          },
        ]}
      />
    </div>
  );
}

export default MerchantDetail;
