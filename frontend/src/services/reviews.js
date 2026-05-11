import api from "./api";

function authHeaders() {
  const token = localStorage.getItem("access_token");
  return token ? { Authorization: `Bearer ${token}` } : {};
}

export function getReviews(merchantId) {
  return api.get(`/merchants/${merchantId}/reviews`);
}

export function createReview(data) {
  return api.post("/reviews", data, { headers: authHeaders() });
}
