import api from "./api";

export function getMerchants(params = {}) {
  return api.get("/merchants", { params });
}

export function getMerchant(id) {
  return api.get(`/merchants/${id}`);
}
