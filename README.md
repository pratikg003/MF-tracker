# MF Tracker
 
A Flutter app for tracking Indian mutual fund investments. Browse every scheme, view each fund's NAV history and returns, log investments and redemptions, and see your portfolio's true annualised return (XIRR).
 
<!-- Add 2–3 screenshots here: Portfolio, Fund detail, SIP calculator -->
 
## Features
 
- **Fund browser.** Search the full list of Indian mutual fund schemes from the public [MFAPI](https://www.mfapi.in/) API.
- **Fund detail.** Interactive NAV history chart with tooltips, live NAV header, and 1, 3 and 5-year CAGR computed from historical NAV data.
- **Portfolio.** Log investments and redemptions as transactions, see invested vs current value per fund using live NAVs, and an allocation pie chart.
- **Portfolio XIRR.** Annualised return across all your transactions, accounting for when each rupee went in or came out.
- **SIP calculator.** Projects the future value of a monthly SIP for a given return and duration.
- **Offline caching.** Fund history is cached in SQLite, so revisiting a fund loads instantly.
## How XIRR is calculated
 
Simple return ignores timing. ₹10,000 invested three years ago and ₹10,000 invested last month shouldn't count the same. XIRR finds the single annual rate `r` that makes the present value of all cash flows zero:
 
```
f(r) = Σ Cᵢ / (1 + r)^tᵢ = 0
```
 
Here `Cᵢ` is each cash flow (investments negative, redemptions and current value positive) and `tᵢ` is years since the first transaction.
 
There's no closed-form solution, so `lib/utils/xirr_calculator.dart` solves it numerically with the **Newton-Raphson method**:
 
```
r(n+1) = r(n) − f(r(n)) / f'(r(n))
f'(r)  = Σ −tᵢ · Cᵢ / (1 + r)^(tᵢ + 1)
```
 
It starts from a 10% guess and iterates until successive estimates differ by less than 0.0001, up to 1,000 iterations. It returns `null` if the derivative hits zero or it fails to converge.
 
## Data model (SQLite)
 
| Table | Purpose |
|---|---|
| `portfolio_funds` | One row per fund you hold |
| `transactions` | Every investment (+) and redemption (−) with date, amount, NAV and units. Foreign key to `portfolio_funds` with `ON DELETE CASCADE` |
| `fund_cache` | Cached fund metadata and serialised NAV history |
 
Portfolio totals come from a single aggregation query (`SUM` of amount and units, `GROUP BY` fund) rather than summing in Dart.
 
## Tech stack
 
Flutter · Dart · SQLite (`sqflite`) · `fl_chart` · `http` · Provider
 
## Project structure
 
```
lib/
├── database/database_helper.dart   # SQLite schema, caching, transactions, aggregation
├── models/                         # MutualFund, FundDetails/NavPoint, PortfolioItem, Transaction
├── screens/                        # Portfolio, Fund browser, Fund detail, SIP calculator
├── utils/
│   ├── xirr_calculator.dart        # Newton-Raphson XIRR
│   ├── performance_calculator.dart # CAGR over 1/3/5 years
│   └── sip_calculator.dart         # SIP future value
└── widgets/allocation_chart.dart
```
 
## Run locally
 
```bash
flutter pub get
flutter run
```
 
No API key needed. MFAPI is public.
 
## Known limitations
 
- Transactions are recorded at the moment you enter them, so past investments can't be backdated yet.
- XIRR can fail to converge for unusual cash-flow patterns. The app shows "--%" instead of a wrong number.
 
