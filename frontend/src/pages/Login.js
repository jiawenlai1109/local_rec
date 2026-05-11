import { useState } from "react";
import { Link, useNavigate } from "react-router-dom";
import { Button, Form, Input, message, Typography } from "antd";
import { UserOutlined, LockOutlined } from "@ant-design/icons";
import { login } from "../services/auth";

const { Title } = Typography;

function Login() {
  const [loading, setLoading] = useState(false);
  const navigate = useNavigate();

  const handleSubmit = (values) => {
    setLoading(true);
    login(values.username, values.password)
      .then(() => {
        message.success("登录成功");
        navigate("/merchants");
      })
      .catch((err) => {
        message.error(err.response?.data?.detail || "登录失败");
      })
      .finally(() => setLoading(false));
  };

  return (
    <div style={{ maxWidth: 400, margin: "60px auto" }}>
      <Title level={3} style={{ textAlign: "center", marginBottom: 32 }}>
        登录
      </Title>
      <Form onFinish={handleSubmit} size="large">
        <Form.Item
          name="username"
          rules={[{ required: true, message: "请输入用户名" }]}
        >
          <Input prefix={<UserOutlined />} placeholder="用户名" />
        </Form.Item>
        <Form.Item
          name="password"
          rules={[{ required: true, message: "请输入密码" }]}
        >
          <Input.Password prefix={<LockOutlined />} placeholder="密码" />
        </Form.Item>
        <Form.Item>
          <Button type="primary" htmlType="submit" loading={loading} block>
            登录
          </Button>
        </Form.Item>
        <div style={{ textAlign: "center" }}>
          还没有账号？<Link to="/register">立即注册</Link>
        </div>
      </Form>
    </div>
  );
}

export default Login;
