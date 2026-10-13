import { useEffect, useState } from "react"
import { Link, useSearchParams } from "react-router-dom"
import { loadInsights } from "../api"
import { QuestionChart } from "../components/Charts"

export default function Questions() {
  const [data, setData] = useState(null)
  const [error, setError] = useState("")
  const [params, setParams] = useSearchParams()

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
  if (!data) return <div className="boot">Preparing answers…</div>

  const selectedId = params.get("q") || data.questions[0]?.id
  const selected = data.questions.find((question) => question.id === selectedId) || data.questions[0]

  return (
    <div className="page">
      <header className="page-head">
        <div>
          <p className="eyebrow">Questions</p>
          <h1>Ask how ACME pays</h1>
          <p className="lede">Each answer is calculated from the current workforce, not a saved spreadsheet tab.</p>
        </div>
      </header>
      <div className="question-layout">
        <ol className="question-list">
          {data.questions.map((question, index) => (
            <li key={question.id}>
              <button
                type="button"
                className={question.id === selected.id ? "active" : ""}
                onClick={() => setParams({ q: question.id })}
              >
                <span>{index + 1}</span>
                {question.prompt}
              </button>
            </li>
          ))}
        </ol>
        <article className="card answer-card">
          <h2>{selected.prompt}</h2>
          <p className="answer">{selected.answer}</p>
          <QuestionChart chart={selected.chart} />
          {selected.people_query ? (
            <Link className="text-link" to={`/people?${selected.people_query}`}>
              Open these people
            </Link>
          ) : null}
        </article>
      </div>
      <p className="footnote">{data.note}</p>
    </div>
  )
}
