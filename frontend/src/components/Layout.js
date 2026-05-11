import { useEffect, useState } from "react";
import { Link, Outlet, useLocation, useNavigate } from "react-router-dom";
import { Layout as AntLayout, Menu, Button, Space, Modal } from "antd";
import { ShopOutlined, OrderedListOutlined } from "@ant-design/icons";
import { deleteAccount } from "../services/auth";

const { Header, Content } = AntLayout;

function Layout() {
  const [hasToken, setHasToken] = useState(
    () => !!localStorage.getItem("access_token")
  );
  const navigate = useNavigate();
  const location = useLocation();

  useEffect(() => {
    setHasToken(!!localStorage.getItem("access_token"));
  }, [location.pathname]);

  const handleLogout = () => {
    localStorage.removeItem("access_token");
    setHasToken(false);
    navigate("/");
  };

  const handleDeleteAccount = () => {
    Modal.confirm({
      title: "确认注销",
      content: "注销后所有数据（点评、订单）将被永久删除，不可恢复。确定要注销账号吗？",
      okText: "确认注销",
      cancelText: "取消",
      okButtonProps: { danger: true },
      onOk: async () => {
        await deleteAccount();
        setHasToken(false);
        navigate("/");
      },
    });
  };

  return (
    <AntLayout style={{ minHeight: "100vh" }}>
      <Header
        style={{
          display: "flex",
          alignItems: "center",
          justifyContent: "space-between",
        }}
      >
        <div style={{ display: "flex", alignItems: "center", gap: 24 }}>
          <Link
            to="/"
            style={{ color: "#fff", fontSize: 20, fontWeight: "bold" }}
          >
            本地推荐
          </Link>
          <Menu
            theme="dark"
            mode="horizontal"
            items={[
              {
                key: "merchants",
                icon: <ShopOutlined />,
                label: <Link to="/merchants">商家列表</Link>,
              },
              {
                key: "orders",
                icon: <OrderedListOutlined />,
                label: <Link to="/orders">我的订单</Link>,
              },
            ]}
            style={{ flex: 1, minWidth: 200 }}
          />
        </div>
        <Space>
          {hasToken ? (
            <>
              <Button onClick={handleLogout}>退出登录</Button>
              <Button danger onClick={handleDeleteAccount}>注销账号</Button>
            </>
          ) : (
            <>
              <Button onClick={() => navigate("/login")}>登录</Button>
              <Button type="primary" onClick={() => navigate("/register")}>
                注册
              </Button>
            </>
          )}
        </Space>
      </Header>
      <Content style={{ padding: 24 }}>
        <Outlet />
      </Content>
    </AntLayout>
  );
}

export default Layout;
