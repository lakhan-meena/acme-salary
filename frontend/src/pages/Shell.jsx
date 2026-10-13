import { NavLink, Outlet } from "react-router-dom"
import { useAuth } from "../auth"

const LINKS = [
  { to: "/", label: "Overview", end: true },
  { to: "/people", label: "People" },
  { to: "/questions", label: "Questions" },
  { to: "/bands", label: "Bands" },
]

export default function Shell() {
  const { user, signOut } = useAuth()

  return (
    <div className="app-shell">
      <aside className="sidebar">
        <div className="brand">
          <span className="brand-mark">P</span>
          <div>
            <strong>Payline</strong>
            <em>ACME</em>
          </div>
        </div>
        <nav>
          {LINKS.map((link) => (
            <NavLink key={link.to} to={link.to} end={link.end}>
              {link.label}
            </NavLink>
          ))}
        </nav>
        <div className="aside-foot">
          <span>{user?.name}</span>
          <button type="button" onClick={signOut}>Sign out</button>
        </div>
      </aside>
      <div className="workspace">
        <Outlet />
      </div>
    </div>
  )
}
