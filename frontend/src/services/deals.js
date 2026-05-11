import api from "./api";

function authHeaders() {
  const token = localStorage.getItem("access_token");
  return token ? { Authorization: `Bearer ${token}` } : {};
}

export function getDealsByMerchant(merchantId) {
  return api.get(`/merchants/${merchantId}/deals`);
}

export function createOrder(dealId) {
  return api.post("/orders", { deal_id: dealId }, { headers: authHeaders() });
}

export function getOrders() {
  return api.get("/orders", { headers: authHeaders() });
}

export function useOrder(orderId) {
  return api.put(`/orders/${orderId}/use`, null, { headers: authHeaders() });
}

export function refundOrder(orderId) {
  return api.put(`/orders/${orderId}/refund`, null, { headers: authHeaders() });
}
