import { createContext, useContext, useEffect, useMemo, useState } from "react"
import { api, getToken, setToken } from "./api"

const AuthContext = createContext(null)

export function AuthProvider({ children }) {
  const [user, setUser] = useState(null)
  const [ready, setReady] = useState(false)

  useEffect(() => {
    let cancelled = false
    const token = getToken()
    if (!token) {
      setReady(true)
      return undefined
    }

    api.me()
      .then((data) => {
        if (!cancelled) setUser(data.user)
      })
      .catch(() => {
        setToken(null)
      })
      .finally(() => {
        if (!cancelled) setReady(true)
      })

    return () => {
      cancelled = true
    }
  }, [])

  useEffect(() => {
    const onUnauthorized = () => setUser(null)
    window.addEventListener("payline:unauthorized", onUnauthorized)
    return () => window.removeEventListener("payline:unauthorized", onUnauthorized)
  }, [])

  const value = useMemo(
    () => ({
      user,
      ready,
      async signIn(email, password) {
        const data = await api.login(email, password)
        setToken(data.token)
        setUser(data.user)
        return data.user
      },
      signOut() {
        setToken(null)
        setUser(null)
      },
    }),
    [user, ready],
  )

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>
}

export function useAuth() {
  return useContext(AuthContext)
}
