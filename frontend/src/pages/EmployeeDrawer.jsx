import { useEffect, useState } from "react"
import { App, Button, Drawer, Form, Input, InputNumber } from "antd"
import { api, clearInsights } from "../api"
import { EMPLOYMENT, GENDER, STATUS, dateLabel, money, moneyExact } from "../format"

export default function EmployeeDrawer({ employeeId, onClose, onSaved }) {
  const { message } = App.useApp()
  const [form] = Form.useForm()
  const [employee, setEmployee] = useState(null)
  const [error, setError] = useState("")
  const [saving, setSaving] = useState(false)

  useEffect(() => {
    if (!employeeId) return undefined
    let cancelled = false
    setEmployee(null)
    setError("")
    api.employee(employeeId)
      .then((data) => {
        if (cancelled) return
        setEmployee(data.employee)
        form.setFieldsValue({
          base_salary_annual: data.employee.base_salary_annual,
          bonus_target_percent: data.employee.bonus_target_percent,
          annual_allowance: data.employee.annual_allowance,
          change_reason: "",
        })
      })
      .catch((err) => {
        if (!cancelled) setError(err.message)
      })
    return () => {
      cancelled = true
    }
  }, [employeeId, form])

  async function onFinish(values) {
    setSaving(true)
    setError("")
    try {
      const data = await api.updateEmployee(employee.id, values)
      clearInsights()
      setEmployee(data.employee)
      form.setFieldValue("change_reason", "")
      message.success("Pay updated")
      onSaved()
    } catch (err) {
      setError(err.details?.errors?.join(" ") || err.message)
    } finally {
      setSaving(false)
    }
  }

  return (
    <Drawer
      title={employee ? employee.full_name : "Person"}
      open={Boolean(employeeId)}
      onClose={onClose}
      width={520}
      destroyOnClose
    >
      {error && !employee ? <p className="form-error">{error}</p> : null}
      {!employee && !error ? <p>Loading record…</p> : null}
      {employee ? (
        <div className="drawer-body">
          <p className="muted">
            {employee.employee_code} · {employee.job_title}
          </p>
          <dl className="facts">
            <div><dt>Location</dt><dd>{employee.city}, {employee.country_name}</dd></div>
            <div><dt>Department</dt><dd>{employee.department} · {employee.job_level}</dd></div>
            <div><dt>Type</dt><dd>{EMPLOYMENT[employee.employment_type]}</dd></div>
            <div><dt>Status</dt><dd>{STATUS[employee.status]}</dd></div>
            <div><dt>Gender</dt><dd>{GENDER[employee.gender]}</dd></div>
            <div><dt>Hired</dt><dd>{dateLabel(employee.hire_date)}</dd></div>
          </dl>

          <BandTrack employee={employee} />

          <div className="cash-line">
            <span>Target cash</span>
            <strong>{money(employee.total_cash_usd)} USD</strong>
            <em>Pay last set {dateLabel(employee.comp_effective_on)} · 1 {employee.currency} = {employee.fx_rate_to_usd} USD</em>
          </div>

          <Form form={form} layout="vertical" onFinish={onFinish} requiredMark={false}>
            <Form.Item label={`Annual base (${employee.currency})`} name="base_salary_annual" rules={[{ required: true }]}>
              <InputNumber min={0} style={{ width: "100%" }} />
            </Form.Item>
            <Form.Item label="Target bonus %" name="bonus_target_percent" rules={[{ required: true }]}>
              <InputNumber min={0} max={100} style={{ width: "100%" }} />
            </Form.Item>
            <Form.Item label={`Annual allowance (${employee.currency})`} name="annual_allowance" rules={[{ required: true }]}>
              <InputNumber min={0} style={{ width: "100%" }} />
            </Form.Item>
            <Form.Item label="Reason for the change" name="change_reason" rules={[{ required: true, message: "Add a reason" }]}>
              <Input.TextArea rows={3} maxLength={500} placeholder="Market adjustment, promotion, correction…" />
            </Form.Item>
            {error ? <p className="form-error">{error}</p> : null}
            <Button type="primary" htmlType="submit" loading={saving}>Save pay</Button>
          </Form>

          <h3>Change history</h3>
          {employee.changes?.length ? (
            <ul className="history">
              {employee.changes.map((change) => (
                <li key={change.id}>
                  <strong>{dateLabel(change.effective_on)}</strong>
                  <span>{change.reason}</span>
                  <em>
                    Base {moneyExact(change.base_salary_before, change.currency)} → {moneyExact(change.base_salary_after, change.currency)}
                  </em>
                </li>
              ))}
            </ul>
          ) : (
            <p className="muted">No pay changes recorded yet.</p>
          )}
        </div>
      ) : null}
    </Drawer>
  )
}

function BandTrack({ employee }) {
  if (employee.band_position === "not_applicable" || !employee.band) {
    return <p className="band-note">Bands apply to full-time annual base. This record is not scored against one.</p>
  }

  const { min, max } = employee.band
  const value = employee.base_salary_annual
  let pct = 50
  if (value <= min) pct = 0
  else if (value >= max) pct = 100
  else pct = ((value - min) / (max - min)) * 100
  const ratio = employee.compa_ratio
  const delta = ratio == null ? null : (ratio - 1) * 100
  const outside = employee.band_position !== "in_band"

  return (
    <div className="band-track">
      <div className="band-caption">
        <span>{outside ? "Outside band" : "In band"}</span>
        <strong>
          {ratio == null ? "—" : ratio.toFixed(2)} compa-ratio
          {delta == null ? "" : ` · ${Math.abs(delta).toFixed(1)}% ${delta >= 0 ? "above" : "below"} midpoint`}
        </strong>
      </div>
      <div className="track">
        <i style={{ left: `${pct}%` }} className={outside ? "out" : ""} />
      </div>
      <div className="band-scale">
        <span>{moneyExact(min, employee.currency)}</span>
        <span>{moneyExact(employee.band.mid, employee.currency)}</span>
        <span>{moneyExact(max, employee.currency)}</span>
      </div>
      <p className="muted">Current base {moneyExact(value, employee.currency)}</p>
    </div>
  )
}
