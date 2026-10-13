const TOKEN_KEY = "payline_token"

let insightsRequest = null

export function getToken() {
  return localStorage.getItem(TOKEN_KEY)
}

export function setToken(token) {
  if (token) localStorage.setItem(TOKEN_KEY, token)
  else localStorage.removeItem(TOKEN_KEY)
}

export function clearInsights() {
  insightsRequest = null
}

function cleanParams(params) {
  const query = {}
  Object.entries(params).forEach(([key, value]) => {
    if (value !== undefined && value !== null && value !== "") query[key] = String(value)
  })
  return query
}

async function request(path, { method = "GET", body } = {}) {
  const headers = { Accept: "application/json" }
  const token = getToken()
  if (token) headers.Authorization = `Bearer ${token}`
  if (body !== undefined) headers["Content-Type"] = "application/json"

  const response = await fetch(path, {
    method,
    headers,
    body: body !== undefined ? JSON.stringify(body) : undefined,
  })

  const text = await response.text()
  const data = text ? JSON.parse(text) : null

  if (response.status === 401 && !path.endsWith("/session")) {
    setToken(null)
    window.dispatchEvent(new Event("payline:unauthorized"))
  }

  if (!response.ok) {
    const message = data?.error || data?.errors?.join(" ") || "Request failed"
    const error = new Error(message)
    error.status = response.status
    error.details = data
    throw error
  }

  return data
}

export const api = {
  login: (email, password) => request("/api/v1/session", { method: "POST", body: { email, password } }),
  me: () => request("/api/v1/session"),
  insights: () => request("/api/v1/insights"),
  employees: (params) => request(`/api/v1/employees?${new URLSearchParams(cleanParams(params))}`),
  employee: (id) => request(`/api/v1/employees/${id}`),
  updateEmployee: (id, employee) =>
    request(`/api/v1/employees/${id}`, { method: "PATCH", body: { employee } }),
  bands: (country) => request(`/api/v1/salary_bands?${new URLSearchParams({ country })}`),
}

export function loadInsights() {
  if (!insightsRequest) {
    insightsRequest = api.insights().catch((error) => {
      insightsRequest = null
      throw error
    })
  }
  return insightsRequest
}
