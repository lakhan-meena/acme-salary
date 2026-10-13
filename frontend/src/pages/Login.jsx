import { useState } from "react"
import { Navigate } from "react-router-dom"
import { Button, Form, Input } from "antd"
import { useAuth } from "../auth"

export default function Login() {
  const { user, ready, signIn } = useAuth()
  const [error, setError] = useState("")
  const [loading, setLoading] = useState(false)

  if (ready && user) return <Navigate to="/" replace />

  async function onFinish(values) {
    setLoading(true)
    setError("")
    try {
      await signIn(values.email, values.password)
    } catch (err) {
      setError(err.message)
    } finally {
      setLoading(false)
    }
  }

  return (
    <div className="login">
      <section className="login-story">
        <p className="eyebrow">ACME compensation</p>
        <h1>Payline</h1>
        <p>Look up how 10,000 people are paid, correct a salary, and answer the questions the spreadsheet could not.</p>
        <ul>
          <li>12 countries, one USD view</li>
          <li>Bands, gaps, and outliers</li>
          <li>Every edit keeps a reason</li>
        </ul>
      </section>
      <section className="login-panel">
        <Form
          layout="vertical"
          onFinish={onFinish}
          requiredMark={false}
          initialValues={{ email: "hr.manager@acme.test", password: "acme-hr-demo" }}
        >
          <h2>Sign in</h2>
          <p className="muted">HR manager workspace. Demo data, not a live payroll.</p>
          <Form.Item label="Email" name="email" rules={[{ required: true, type: "email" }]}>
            <Input size="large" autoComplete="username" />
          </Form.Item>
          <Form.Item label="Password" name="password" rules={[{ required: true }]}>
            <Input.Password size="large" autoComplete="current-password" />
          </Form.Item>
          {error ? <p className="form-error">{error}</p> : null}
          <Button type="primary" htmlType="submit" size="large" block loading={loading}>
            Enter Payline
          </Button>
          <p className="demo-note">
            Demo sign-in is filled in: hr.manager@acme.test / acme-hr-demo
          </p>
        </Form>
      </section>
    </div>
  )
}
