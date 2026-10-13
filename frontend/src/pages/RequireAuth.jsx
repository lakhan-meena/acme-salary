import { Navigate, Outlet } from "react-router-dom"
import { useAuth } from "../auth"

export default function RequireAuth() {
  const { user, ready } = useAuth()
  if (!ready) return <div className="boot">Opening Payline…</div>
  if (!user) return <Navigate to="/login" replace />
  return <Outlet />
}
