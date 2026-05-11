import { BrowserRouter, Routes, Route } from "react-router-dom";
import Layout from "./components/Layout";
import MerchantList from "./pages/MerchantList";
import MerchantDetail from "./pages/MerchantDetail";
import Login from "./pages/Login";
import Register from "./pages/Register";
import Orders from "./pages/Orders";

function App() {
  return (
    <BrowserRouter>
      <Routes>
        <Route element={<Layout />}>
          <Route path="/" element={<MerchantList />} />
          <Route path="/merchants" element={<MerchantList />} />
          <Route path="/merchant/:id" element={<MerchantDetail />} />
          <Route path="/login" element={<Login />} />
          <Route path="/register" element={<Register />} />
          <Route path="/orders" element={<Orders />} />
        </Route>
      </Routes>
    </BrowserRouter>
  );
}

export default App;
