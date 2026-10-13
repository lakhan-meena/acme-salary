# Payline — requirements

**Product:** Payline, a web app for ACME’s HR manager.
**Goal:** Replace the salary spreadsheets for 10,000 employees in 12 countries with one place to look up pay, correct it, and answer how ACME pays people.

## Who it is for

One persona: the HR manager. She needs the current cash picture (base, target bonus, allowances), not a payroll run. She searches for a person, filters the workforce, updates pay with a reason, and reads plain-language answers backed by the same data.

## In scope

- **Directory.** All 10,000 employees, searched by name, email, or employee code, and filtered by country, department, level, status, and employment type. The list is paged and sorted on the server so it stays usable at this size.
- **Salary record.** Local-currency base, target bonus percent, annual allowance, level, title, department, and status. Totals are also shown in USD so countries can be compared.
- **Edits with a trail.** A pay change requires a reason. Payline stores the previous amounts, the new amounts, and the date of the change. Gender is stored only so equity can be measured in aggregate; it is not shown on a person’s page.
- **Salary bands.** Each country and level has a minimum, midpoint, and maximum. Full-time base pay is marked below, inside, or above that band. Part-time and contractor pay is listed, and not scored against the full-time band.
- **Questions.** Pre-written questions an HR manager actually asks: total cash cost, where payroll sits versus headcount, pay by level, cost per person by department, gender pay gap at the same level, who is outside band, how much of cash is bonus versus base, and how contractors compare with employees. Each answer is a sentence plus a chart from live data.
- **Sign-in.** One HR manager account. This is an internal tool, not a public site.
- **Seed.** `bin/rails db:seed` loads exactly 10,000 synthetic employees, bands, and the HR user. Pay, geography, and a modest gender gap are generated so the questions have something real to say. Figures are not ACME’s actual payroll.

Comparisons use a **fixed FX snapshot** stored on each employee. Cash means base + target bonus + allowances. Terminated people stay in the directory and drop out of the cost answers.

## Left out, on purpose

- **Paying people.** No tax, bank files, payslips, or payroll calendars. Payline explains and maintains salary data; it does not move money. Those rules differ by country and would dwarf the HR questions this tool is for.
- **Equity grants, benefits, and variable commissions already earned.** Only target bonus percent is in scope, because that is what the spreadsheets were being used to compare.
- **Approval chains, merit cycles, and offer letters.** The manager edits the record directly. A workflow would hide the core task behind process the org has not defined.
- **Employee self-service, SSO, and role matrices.** The user is one HR manager. A second login type is out until employees are actually invited in.
- **Live exchange rates.** A moving FX feed would change answers between visits and make a compensation conversation harder, not clearer. Rates are a labeled snapshot.
- **Individual gender on the profile.** Equity is an aggregate question. Showing gender on every salary edit invites misuse without helping the edit.

## Fit

Rails API and SQLite hold the records and the aggregates. React is the HR workspace. SQLite is enough for 10,000 rows with indexes and paged queries; the insights read that workforce in one pass and summarize it in Ruby.
