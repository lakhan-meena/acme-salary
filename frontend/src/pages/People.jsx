import { useEffect, useState } from "react"
import { useSearchParams } from "react-router-dom"
import { Button, Input, Select, Table, Tag } from "antd"
import { api } from "../api"
import { EMPLOYMENT, STATUS, count, money, moneyExact } from "../format"
import EmployeeDrawer from "./EmployeeDrawer"

const BAND_TAG = {
  in_band: { color: "green", label: "In band" },
  below: { color: "gold", label: "Below" },
  above: { color: "red", label: "Above" },
  not_applicable: { color: "default", label: "Not banded" },
}

export default function People() {
  const [params, setParams] = useSearchParams()
  const [draftQ, setDraftQ] = useState(params.get("q") || "")
  const [data, setData] = useState(null)
  const [error, setError] = useState("")
  const [loading, setLoading] = useState(true)
  const [reloadKey, setReloadKey] = useState(0)
  const [openId, setOpenId] = useState(null)

  useEffect(() => {
    setDraftQ(params.get("q") || "")
  }, [params])

  useEffect(() => {
    const handle = setTimeout(() => {
      if ((params.get("q") || "") !== draftQ) {
        update({ q: draftQ }, { resetPage: true })
      }
    }, 300)
    return () => clearTimeout(handle)
  }, [draftQ])

  useEffect(() => {
    let cancelled = false
    setLoading(true)
    setError("")
    api.employees({
      q: params.get("q") || "",
      country: params.get("country") || "",
      department: params.get("department") || "",
      level: params.get("level") || "",
      status: params.get("status") || "current",
      employment_type: params.get("employment_type") || "",
      band: params.get("band") || "",
      page: params.get("page") || 1,
      per_page: params.get("per_page") || 25,
      sort: params.get("sort") || "code",
      direction: params.get("direction") || "asc",
    })
      .then((payload) => {
        if (!cancelled) setData(payload)
      })
      .catch((err) => {
        if (!cancelled) setError(err.message)
      })
      .finally(() => {
        if (!cancelled) setLoading(false)
      })
    return () => {
      cancelled = true
    }
  }, [params, reloadKey])

  function update(next, { resetPage = false } = {}) {
    const merged = Object.fromEntries(params.entries())
    Object.entries(next).forEach(([key, value]) => {
      if (value === "" || value == null) delete merged[key]
      else merged[key] = String(value)
    })
    if (resetPage) merged.page = "1"
    setParams(merged)
  }

  const filters = data?.filters
  const band = params.get("band")

  return (
    <div className="page">
      <header className="page-head">
        <div>
          <p className="eyebrow">People</p>
          <h1>Salary records</h1>
          <p className="lede">
            {data
              ? `${count(data.meta.total)} ${data.meta.total === 1 ? "person matches" : "people match"}`
              : "Search the workforce"}
            {band ? " · full-time band filter is on" : ""}
          </p>
        </div>
      </header>

      <div className="filters">
        <Input
          allowClear
          placeholder="Name, email, or employee code"
          value={draftQ}
          onChange={(event) => setDraftQ(event.target.value)}
          style={{ width: 280 }}
        />
        <Select
          allowClear
          placeholder="Country"
          value={params.get("country") || undefined}
          style={{ width: 180 }}
          options={(filters?.countries || []).map((row) => ({ value: row.code, label: row.name }))}
          onChange={(value) => update({ country: value || "" }, { resetPage: true })}
        />
        <Select
          allowClear
          placeholder="Department"
          value={params.get("department") || undefined}
          style={{ width: 180 }}
          options={(filters?.departments || []).map((row) => ({ value: row, label: row }))}
          onChange={(value) => update({ department: value || "" }, { resetPage: true })}
        />
        <Select
          allowClear
          placeholder="Level"
          value={params.get("level") || undefined}
          style={{ width: 110 }}
          options={(filters?.levels || []).map((row) => ({ value: row, label: row }))}
          onChange={(value) => update({ level: value || "" }, { resetPage: true })}
        />
        <Select
          placeholder="Status"
          value={params.get("status") || "current"}
          style={{ width: 190 }}
          options={(filters?.statuses || [{ value: "current", label: "Active and on leave" }]).map((row) => ({
            value: row.value,
            label: row.label,
          }))}
          onChange={(value) => update({ status: value }, { resetPage: true })}
        />
        <Select
          allowClear
          placeholder="Employment"
          value={params.get("employment_type") || undefined}
          style={{ width: 150 }}
          options={(filters?.employment_types || []).map((row) => ({ value: row.value, label: row.label }))}
          onChange={(value) => update({ employment_type: value || "" }, { resetPage: true })}
        />
        <Select
          allowClear
          placeholder="Band"
          value={params.get("band") || undefined}
          style={{ width: 150 }}
          options={(filters?.bands || []).map((row) => ({ value: row.value, label: row.label }))}
          onChange={(value) => update({ band: value || "" }, { resetPage: true })}
        />
        <Button
          onClick={() => {
            setDraftQ("")
            setParams({})
          }}
        >
          Reset
        </Button>
      </div>

      {error ? <p className="form-error">{error}</p> : null}

      <Table
        className="people-table"
        rowKey="id"
        loading={loading}
        dataSource={data?.employees || []}
        pagination={{
          current: data?.meta.page || 1,
          pageSize: data?.meta.per_page || 25,
          total: data?.meta.total || 0,
          showSizeChanger: true,
          pageSizeOptions: [25, 50, 100],
        }}
        onChange={(pagination, _filters, sorter) => {
          update({
            page: pagination.current,
            per_page: pagination.pageSize,
            sort: sorter?.order ? sorter.columnKey : "code",
            direction: sorter?.order === "descend" ? "desc" : "asc",
          })
        }}
        onRow={(record) => ({ onClick: () => setOpenId(record.id) })}
        columns={[
          { title: "Code", dataIndex: "employee_code", key: "code", sorter: true, width: 120 },
          { title: "Person", dataIndex: "full_name", key: "name", sorter: true },
          { title: "Country", dataIndex: "country_name", key: "country", sorter: true },
          { title: "Department", dataIndex: "department", key: "department", sorter: true },
          { title: "Level", dataIndex: "job_level", key: "level", sorter: true, width: 90 },
          {
            title: "Base",
            key: "base_usd",
            sorter: true,
            align: "right",
            render: (_, row) => (
              <div>
                <div>{moneyExact(row.base_salary_annual, row.currency)}</div>
                <div className="muted">{money(row.base_salary_usd)}</div>
              </div>
            ),
          },
          {
            title: "Band",
            dataIndex: "band_position",
            width: 120,
            render: (value) => {
              const tag = BAND_TAG[value] || BAND_TAG.not_applicable
              return <Tag color={tag.color}>{tag.label}</Tag>
            },
          },
          {
            title: "Status",
            dataIndex: "status",
            width: 110,
            render: (value) => STATUS[value] || value,
          },
          {
            title: "Type",
            dataIndex: "employment_type",
            width: 120,
            render: (value) => EMPLOYMENT[value] || value,
          },
        ]}
      />

      <EmployeeDrawer
        employeeId={openId}
        onClose={() => setOpenId(null)}
        onSaved={() => setReloadKey((value) => value + 1)}
      />
    </div>
  )
}
