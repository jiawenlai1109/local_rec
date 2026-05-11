import { useState } from "react";
import { Link, useNavigate } from "react-router-dom";
import { Button, Form, Input, message, Typography } from "antd";
import { UserOutlined, LockOutlined } from "@ant-design/icons";
import { register } from "../services/auth";

const { Title } = Typography;

function Register() {
  const [loading, setLoading] = useState(false);
  const navigate = useNavigate();

  const handleSubmit = (values) => {
    if (values.password !== values.confirmPassword) {
      message.error("两次输入的密码不一致");
      return;
    }
    setLoading(true);
    register(values.username, values.password)
      .then(() => {
        message.success("注册成功，请登录");
        navigate("/login");
      })
      .catch((err) => {
        message.error(err.response?.data?.detail || "注册失败");
      })
      .finally(() => setLoading(false));
  };

  return (
    <div style={{ maxWidth: 400, margin: "60px auto" }}>
      <Title level={3} style={{ textAlign: "center", marginBottom: 32 }}>
        注册
      </Title>
      <Form onFinish={handleSubmit} size="large">
        <Form.Item
          name="username"
          rules={[
            { required: true, message: "请输入用户名" },
            { min: 2, message: "用户名至少 2 个字符" },
          ]}
        >
          <Input prefix={<UserOutlined />} placeholder="用户名" />
        </Form.Item>
        <Form.Item
          name="password"
          rules={[
            { required: true, message: "请输入密码" },
            { min: 6, message: "密码至少 6 个字符" },
          ]}
        >
          <Input.Password prefix={<LockOutlined />} placeholder="密码" />
        </Form.Item>
        <Form.Item
          name="confirmPassword"
          rules={[{ required: true, message: "请确认密码" }]}
        >
          <Input.Password prefix={<LockOutlined />} placeholder="确认密码" />
        </Form.Item>
        <Form.Item>
          <Button type="primary" htmlType="submit" loading={loading} block>
            注册
          </Button>
        </Form.Item>
        <div style={{ textAlign: "center" }}>
          已有账号？<Link to="/login">去登录</Link>
        </div>
      </Form>
    </div>
  );
}

export default Register;
