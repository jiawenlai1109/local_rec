import { useCallback, useEffect, useState } from "react";
import { useNavigate } from "react-router-dom";
import { Button, Card, Empty, List, message, Modal, Spin, Tag, Typography } from "antd";
import { ShoppingOutlined } from "@ant-design/icons";
import { getOrders, refundOrder, useOrder } from "../services/deals";

const { Text, Title } = Typography;

function Orders() {
  const navigate = useNavigate();
  const [orders, setOrders] = useState([]);
  const [loading, setLoading] = useState(true);

  const fetchOrders = useCallback(() => {
    setLoading(true);
    getOrders()
      .then((res) => setOrders(res.data.data))
      .finally(() => setLoading(false));
  }, []);

  useEffect(() => {
    if (!localStorage.getItem("access_token")) {
      navigate("/login");
      return;
    }
    fetchOrders();
  }, [navigate, fetchOrders]);

  const handleUse = (order) => {
    Modal.confirm({
      title: "确认使用",
      content: `确定要使用「${order.deal.title}」吗？`,
      okText: "确认",
      cancelText: "取消",
      onOk: async () => {
        await useOrder(order.id);
        message.success("使用成功");
        fetchOrders();
      },
    });
  };

  const handleRefund = (order) => {
    Modal.confirm({
      title: "确认退款",
      content: `确定要退款「${order.deal.title}」吗？退款后不可恢复。`,
      okText: "确认退款",
      cancelText: "取消",
      okButtonProps: { danger: true },
      onOk: async () => {
        await refundOrder(order.id);
        message.success("退款成功");
        fetchOrders();
      },
    });
  };

  if (loading) {
    return (
      <div style={{ textAlign: "center", padding: 80 }}>
        <Spin size="large" />
      </div>
    );
  }

  return (
    <div style={{ maxWidth: 800, margin: "0 auto" }}>
      <Title level={3} style={{ marginBottom: 24 }}>
        <ShoppingOutlined /> 我的订单
      </Title>

      {orders.length === 0 ? (
        <Empty description="暂无订单" />
      ) : (
        <List
          dataSource={orders}
          renderItem={(order) => (
            <List.Item>
              <Card style={{ width: "100%" }} size="small">
                <div
                  style={{
                    display: "flex",
                    justifyContent: "space-between",
                    alignItems: "flex-start",
                  }}
                >
                  <div style={{ flex: 1 }}>
                    <div style={{ marginBottom: 8 }}>
                      <Text strong style={{ fontSize: 16 }}>
                        {order.deal.title}
                      </Text>
                      <Tag
                        color={
                          order.status === "待使用" ? "blue"
                          : order.status === "已使用" ? "green"
                          : "orange"
                        }
                        style={{ marginLeft: 8 }}
                      >
                        {order.status}
                      </Tag>
                    </div>
                    <div style={{ color: "#8c8c8c", marginBottom: 4 }}>
                      商家：{order.merchant_name}
                    </div>
                    <div>
                      <Text delete style={{ marginRight: 12 }}>
                        ¥{order.deal.original_price}
                      </Text>
                      <Text style={{ fontSize: 18, color: "#f5222d", fontWeight: "bold" }}>
                        ¥{order.deal.deal_price}
                      </Text>
                      <Text style={{ marginLeft: 16, color: "#bfbfbf", fontSize: 12 }}>
                        购买于 {new Date(order.created_at).toLocaleString()}
                      </Text>
                    </div>
                  </div>
                  {order.status === "待使用" && (
                    <div style={{ display: "flex", gap: 8, flexShrink: 0 }}>
                      <Button type="primary" onClick={() => handleUse(order)}>
                        去使用
                      </Button>
                      <Button danger onClick={() => handleRefund(order)}>
                        退款
                      </Button>
                    </div>
                  )}
                </div>
              </Card>
            </List.Item>
          )}
        />
      )}
    </div>
  );
}

export default Orders;
