# Payline

Web app for ACME's HR manager to manage salary data for 10,000 employees and answer how the organization pays people.

Requirements are in [REQUIREMENTS.md](REQUIREMENTS.md).

## Run

From this folder, with Ruby 3.2+ and Node 22:

```bash
cd backend
bundle install
bin/rails db:prepare
bin/rails db:seed
bin/rails server
```

In another terminal:

```bash
cd frontend
npm install
npm run dev
```

Open http://127.0.0.1:5173

Sign in as `hr.manager@acme.test` / `acme-hr-demo`.

`db:seed` loads 10,000 synthetic employees. Running it again replaces employees, bands, pay history, and the HR user.

## Tests

```bash
cd backend
bin/rails test
```

## Stack

Rails 8 API and SQLite, React (Vite) and Ant Design. The UI talks to `/api/v1` through the Vite dev proxy.
