import axios from "axios";

const api = axios.create({
  baseURL: "http://localhost:8000/api",
});

// 请求拦截：仅当 token 存在时设置，不做删除（避免覆盖外部传入的 header）
api.interceptors.request.use((config) => {
  const token = localStorage.getItem("access_token");
  if (token && !config.headers.Authorization) {
    config.headers.Authorization = `Bearer ${token}`;
  }
  return config;
});

// 响应拦截：401 清 token 并跳转
api.interceptors.response.use(
  (response) => response,
  (error) => {
    if (error.response?.status === 401) {
      localStorage.removeItem("access_token");
      window.location.href = "/login";
    }
    return Promise.reject(error);
  }
);

export default api;
