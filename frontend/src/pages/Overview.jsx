import { useEffect, useState } from "react"
import { Link } from "react-router-dom"
import { Table } from "antd"
import { loadInsights } from "../api"
import { HorizontalBars, MixBar } from "../components/Charts"
import { compactMoney, count, money, percent } from "../format"

export default function Overview() {
  const [data, setData] = useState(null)
  const [error, setError] = useState("")

  useEffect(() => {
    let cancelled = false
    loadInsights()
      .then((payload) => {
        if (!cancelled) setData(payload)
      })
      .catch((err) => {
        if (!cancelled) setError(err.message)
      })
    return () => {
      cancelled = true
    }
  }, [])

  if (error) return <p className="form-error">{error}</p>
  if (!data) return <div className="boot">Adding up payroll…</div>

  const { kpis, workforce } = data
  const mixPoints = [
    { label: "Base", value: data.pay_mix.base_usd, share: data.pay_mix.base_usd / data.pay_mix.total_usd },
    { label: "Target bonus", value: data.pay_mix.bonus_usd, share: data.pay_mix.bonus_usd / data.pay_mix.total_usd },
    { label: "Allowance", value: data.pay_mix.allowance_usd, share: data.pay_mix.allowance_usd / data.pay_mix.total_usd },
  ]

  return (
    <div className="page">
      <header className="page-head">
        <div>
          <p className="eyebrow">Overview</p>
          <h1>How ACME pays</h1>
          <p className="lede">{data.headline}</p>
        </div>
        <span className="pill">Synthetic data</span>
      </header>

      <section className="kpi-grid">
        <article>
          <span>Current people</span>
          <strong>{count(workforce.current)}</strong>
          <em>{count(workforce.active)} active · {count(workforce.on_leave)} on leave</em>
        </article>
        <article>
          <span>Target annual cash</span>
          <strong>{compactMoney(kpis.annual_payroll_usd)}</strong>
          <em>{money(kpis.annual_payroll_usd)}</em>
        </article>
        <article>
          <span>Median full-time base</span>
          <strong>{compactMoney(kpis.median_base_usd)}</strong>
          <em>Average {money(kpis.average_base_usd)}</em>
        </article>
        <article>
          <span>Outside band</span>
          <strong>{count(kpis.outside_band_count)}</strong>
          <em>
            <Link to="/people?band=outside">{percent(kpis.outside_band_rate)} of full-time</Link>
          </em>
        </article>
      </section>

      <section className="split">
        <article className="card">
          <h2>Payroll by country</h2>
          <HorizontalBars points={data.by_country.map((row) => ({ label: row.label, value: row.payroll_usd }))} />
        </article>
        <article className="card">
          <h2>Pay mix</h2>
          <p className="muted">Target cash for current employees, in USD.</p>
          <MixBar points={mixPoints} />
        </article>
      </section>

      <section className="card">
        <h2>Departments</h2>
        <Table
          rowKey="label"
          pagination={false}
          dataSource={data.by_department}
          columns={[
            { title: "Department", dataIndex: "label" },
            { title: "People", dataIndex: "headcount", render: count, align: "right" },
            { title: "Payroll", dataIndex: "payroll_usd", render: (value) => money(value), align: "right" },
            { title: "Share", dataIndex: "share", render: percent, align: "right" },
            { title: "Full-time median base", dataIndex: "median_base_usd", render: (value) => money(value), align: "right" },
          ]}
        />
      </section>
      <p className="footnote">{data.note}</p>
    </div>
  )
}
