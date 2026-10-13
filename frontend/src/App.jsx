import { BrowserRouter, Navigate, Route, Routes } from "react-router-dom"
import { AuthProvider } from "./auth"
import Bands from "./pages/Bands"
import Login from "./pages/Login"
import Overview from "./pages/Overview"
import People from "./pages/People"
import Questions from "./pages/Questions"
import RequireAuth from "./pages/RequireAuth"
import Shell from "./pages/Shell"

export default function App() {
  return (
    <BrowserRouter>
      <AuthProvider>
        <Routes>
          <Route path="/login" element={<Login />} />
          <Route element={<RequireAuth />}>
            <Route element={<Shell />}>
              <Route index element={<Overview />} />
              <Route path="people" element={<People />} />
              <Route path="questions" element={<Questions />} />
              <Route path="bands" element={<Bands />} />
            </Route>
          </Route>
          <Route path="*" element={<Navigate to="/" replace />} />
        </Routes>
      </AuthProvider>
    </BrowserRouter>
  )
}
