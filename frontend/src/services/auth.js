import api from "./api";

export function register(username, password) {
  return api.post("/register", { username, password });
}

export function login(username, password) {
  return api.post("/login", { username, password }).then((res) => {
    localStorage.setItem("access_token", res.data.data.access_token);
    return res.data;
  });
}

export function deleteAccount() {
  return api.delete("/users/me").then((res) => {
    localStorage.removeItem("access_token");
    return res.data;
  });
}
