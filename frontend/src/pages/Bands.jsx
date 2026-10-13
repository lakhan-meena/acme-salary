import { useEffect, useState } from "react"
import { Select, Table } from "antd"
import { api } from "../api"
import { count, money, moneyExact } from "../format"

export default function Bands() {
  const [country, setCountry] = useState("US")
  const [data, setData] = useState(null)
  const [error, setError] = useState("")

  useEffect(() => {
    let cancelled = false
    setError("")
    api.bands(country)
      .then((payload) => {
        if (!cancelled) setData(payload)
      })
      .catch((err) => {
        if (!cancelled) setError(err.message)
      })
    return () => {
      cancelled = true
    }
  }, [country])

  const currency = data?.country?.currency || "USD"

  return (
    <div className="page">
      <header className="page-head">
        <div>
          <p className="eyebrow">Salary bands</p>
          <h1>Full-time ranges by level</h1>
          <p className="lede">
            Min, mid, and max are annual base in local currency. Compa-ratio on a person is their base divided by the midpoint.
          </p>
        </div>
        <Select
          value={country}
          onChange={setCountry}
          style={{ width: 240 }}
          options={(data?.countries || [{ code: "US", name: "United States" }]).map((row) => ({
            value: row.code,
            label: row.name,
          }))}
        />
      </header>
      {error ? <p className="form-error">{error}</p> : null}
      <section className="card">
        <Table
          rowKey="job_level"
          loading={!data && !error}
          pagination={false}
          dataSource={data?.bands || []}
          columns={[
            { title: "Level", dataIndex: "job_level" },
            { title: "Track", dataIndex: "title_hint" },
            { title: "Minimum", dataIndex: "min", align: "right", render: (value) => moneyExact(value, currency) },
            { title: "Midpoint", dataIndex: "mid", align: "right", render: (value) => moneyExact(value, currency) },
            { title: "Maximum", dataIndex: "max", align: "right", render: (value) => moneyExact(value, currency) },
            { title: "Full-time people", dataIndex: "headcount", align: "right", render: count },
            { title: "Median base", dataIndex: "median_base", align: "right", render: (value) => money(value, currency) },
            { title: "Outside", dataIndex: "outside_count", align: "right", render: count },
          ]}
        />
      </section>
      <p className="footnote">
        Part-time and contractor pay is stored on the person, and is not scored against these full-time bands.
        USD comparisons elsewhere use the snapshot rate on each employee.
      </p>
    </div>
  )
}
