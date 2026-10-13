import {
  Bar,
  BarChart,
  CartesianGrid,
  Legend,
  ResponsiveContainer,
  Tooltip,
  XAxis,
  YAxis,
} from "recharts"
import { compactMoney, money, percent } from "../format"

function usdTick(value) {
  return compactMoney(value)
}

export function HorizontalBars({ points, color = "#1f6b4a" }) {
  const data = points.map((point) => ({ ...point, value: Number(point.value) || 0 }))
  const height = Math.max(240, data.length * 36)

  return (
    <ResponsiveContainer width="100%" height={height}>
      <BarChart data={data} layout="vertical" margin={{ top: 4, right: 16, left: 8, bottom: 4 }}>
        <CartesianGrid stroke="#efe6d8" horizontal={false} />
        <XAxis type="number" tickFormatter={usdTick} tick={{ fill: "#5e584e", fontSize: 12 }} />
        <YAxis
          type="category"
          dataKey="label"
          width={128}
          tick={{ fill: "#1c2420", fontSize: 12 }}
        />
        <Tooltip formatter={(value) => money(value)} />
        <Bar dataKey="value" fill={color} radius={[0, 4, 4, 0]} barSize={16} />
      </BarChart>
    </ResponsiveContainer>
  )
}

export function EquityChart({ points }) {
  const data = points
    .filter((point) => point.women != null || point.men != null)
    .map((point) => ({
      label: point.label,
      Women: point.women || 0,
      Men: point.men || 0,
    }))

  return (
    <ResponsiveContainer width="100%" height={320}>
      <BarChart data={data} margin={{ top: 8, right: 8, left: 8, bottom: 4 }}>
        <CartesianGrid stroke="#efe6d8" vertical={false} />
        <XAxis dataKey="label" tick={{ fill: "#1c2420", fontSize: 12 }} />
        <YAxis tickFormatter={usdTick} tick={{ fill: "#5e584e", fontSize: 12 }} />
        <Tooltip formatter={(value) => money(value)} />
        <Legend />
        <Bar dataKey="Women" fill="#1f6b4a" radius={[4, 4, 0, 0]} />
        <Bar dataKey="Men" fill="#c4a15a" radius={[4, 4, 0, 0]} />
      </BarChart>
    </ResponsiveContainer>
  )
}

export function MixBar({ points }) {
  const total = points.reduce((sum, point) => sum + Number(point.value || 0), 0)
  return (
    <div className="mix">
      <div className="mix-track">
        {points.map((point) => (
          <span
            key={point.label}
            className={`mix-seg mix-${point.label.toLowerCase().replace(/\s+/g, "-")}`}
            style={{ width: total ? `${(Number(point.value) / total) * 100}%` : 0 }}
            title={`${point.label} ${money(point.value)}`}
          />
        ))}
      </div>
      <ul>
        {points.map((point) => (
          <li key={point.label}>
            <strong>{point.label}</strong>
            <span>{money(point.value)}</span>
            <em>{percent(point.share)}</em>
          </li>
        ))}
      </ul>
    </div>
  )
}

export function SplitStats({ points }) {
  return (
    <div className="split-stats">
      {points.map((point) => (
        <div key={point.label}>
          <span>{point.label}</span>
          <strong>{Number(point.value).toLocaleString("en-US")}</strong>
        </div>
      ))}
    </div>
  )
}

export function QuestionChart({ chart }) {
  if (!chart) return null
  if (chart.kind === "bar") return <HorizontalBars points={chart.points} />
  if (chart.kind === "equity") return <EquityChart points={chart.points} />
  if (chart.kind === "mix") return <MixBar points={chart.points} />
  if (chart.kind === "split") return <SplitStats points={chart.points} />
  return null
}
