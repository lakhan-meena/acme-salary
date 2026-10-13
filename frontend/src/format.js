export const GENDER = {
  female: "Women",
  male: "Men",
  non_binary: "Non-binary",
  undisclosed: "Undisclosed",
}

export const STATUS = {
  active: "Active",
  on_leave: "On leave",
  terminated: "Terminated",
}

export const EMPLOYMENT = {
  full_time: "Full time",
  part_time: "Part time",
  contractor: "Contractor",
}

export function money(value, currency = "USD") {
  if (value == null || Number.isNaN(Number(value))) return "—"
  return new Intl.NumberFormat("en-US", {
    style: "currency",
    currency,
    maximumFractionDigits: 0,
  }).format(Number(value))
}

export function moneyExact(value, currency = "USD") {
  if (value == null || Number.isNaN(Number(value))) return "—"
  return new Intl.NumberFormat("en-US", {
    style: "currency",
    currency,
    maximumFractionDigits: currency === "JPY" ? 0 : 2,
  }).format(Number(value))
}

export function compactMoney(value) {
  if (value == null || Number.isNaN(Number(value))) return "—"
  return new Intl.NumberFormat("en-US", {
    style: "currency",
    currency: "USD",
    notation: "compact",
    maximumFractionDigits: 1,
  }).format(Number(value))
}

export function count(value) {
  return new Intl.NumberFormat("en-US").format(Number(value || 0))
}

export function percent(rate) {
  if (rate == null || Number.isNaN(Number(rate))) return "—"
  return `${(Number(rate) * 100).toFixed(1)}%`
}

export function dateLabel(iso) {
  if (!iso) return "—"
  const [year, month, day] = String(iso).slice(0, 10).split("-").map(Number)
  return new Intl.DateTimeFormat("en-GB", {
    day: "numeric",
    month: "short",
    year: "numeric",
  }).format(new Date(year, month - 1, day))
}
