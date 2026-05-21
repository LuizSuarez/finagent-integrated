---
trigger: always_on
---

---

## System Identity
- *Role:* Autonomous financial analyst + portfolio actor
- *Orchestrator:* Google Antigravity (all agent routing — no direct agent-to-agent calls)
- *Mode:* Fully autonomous, no human-in-the-loop
- *Data policy:* No real PII; mock-safe datasets only

---

## Non-Negotiable Rules
1. Every agent output *must* include reasoning_trace: list[str] (≥3 entries)
2. All agent dispatch goes through Antigravity — never call agents directly
3. Insights that restate headlines are *rejected* — must combine ≥2 signal types
4. Portfolio allocation must always sum to 100% post-execution
5. System must complete full pipeline even when all live APIs fail (mock fallback)
6. Confidence < 0.65 → flag low_confidence: true, still execute
7. Demo pipeline runtime target: < 15 seconds

---

## Agent Pipeline

| # | Agent ID | Purpose | Key Output Field |
|---|---|---|---|
| 1 | input_intelligence | Normalize news/RSS/social → FinancialEvent | urgency_score |
| 2 | market_context | Enrich with live prices (yfinance) | day_change_pct, volatility_7d |
| 3 | news_intelligence | Entity extraction + causal chains | sector_impact, causal_chain |
| 4 | sentiment_analysis | VADER + TextBlob composite score | composite_score, market_mood |
| 5 | insight_extraction | Cross-signal non-trivial insight | severity, confidence |
| 6 | portfolio_risk | Exposure calc + expected loss | risk_level, expected_loss_usd |
| 7 | decision | Rule-based + Gemini action plan | action_plan[] |
| 8 | trade_simulation | Mock trade execution + DB state diff | before_snapshot, after_snapshot |
| 9 | notification_visualization | Alerts + BEFORE/AFTER charts | risk_reduction_summary |

*Parallel execution:* Agents 2 & 3 run simultaneously after Agent 1. Antigravity manages the join gate.

---

## Sentiment Thresholds
| Score | Mood |
|---|---|
| > 0.5 | GREED |
| 0.2–0.5 | OPTIMISTIC |
| ±0.2 | NEUTRAL |
| −0.5–−0.2 | CAUTIOUS |
| < −0.5 | FEAR |

*Formula:* composite = (0.6 × vader) + (0.4 × textblob)

---

## Risk Levels
| Sector Exposure % | Risk Level |
|---|---|
| < 15% | LOW |
| 15–25% | MEDIUM |
| 25–40% | HIGH |
| > 40% | CRITICAL |

*Decision trigger:* risk_level ∈ [HIGH, CRITICAL] AND exposure > 20% → generate SELL order. sentiment = FEAR AND positive_sector < 30% → generate BUY hedge.

---

## Data Sources & Fallback

News:   NewsAPI → GNews → Finnhub → MarketAux → mock_news_feed.json
Stock:  yfinance (primary, free) → Alpha Vantage → Twelve Data
Social: mock_social.json ONLY (no Twitter/X API)
RSS:    Reuters · Yahoo Finance · CNBC · Investing.com

Cache stock prices in Firebase with 5-min TTL. Log which tier was used per call.

---

## Key Schemas (condensed)

*AgentContract* (all agents must conform):
python
agent_id: str | input_schema: dict | output_schema: dict
reasoning_trace: list[str] | confidence_score: float
execution_time_ms: int | fallback_triggered: bool


*PipelineContext* (Antigravity shared memory):
python
run_id | trigger_event | market_context | sentiment | insight
risk | decision | execution | trace_log | started_at | completed_at


*TradeLog* (append-only, Firebase):
json
{ "trade_id", "timestamp", "action": "BUY|SELL", "asset",
  "quantity", "mock_price", "slippage_applied_pct", "status": "EXECUTED" }


*PortfolioSnapshot* (before + after, Firebase):
json
{ "snapshot_id", "holdings": { "ASSET": { "allocation_pct", "value" } },
  "risk_level", "risk_score" }


---

## Tech Stack
| Layer | Choice |
|---|---|
| Backend | FastAPI + asyncio |
| Orchestration | Google Antigravity |
| LLM enrichment | Gemini API |
| NLP | spaCy + VADER + TextBlob |
| Database | Firebase Firestore (realtime) |
| Frontend | Flutter (fl_chart) |
| Stock data | yfinance → Alpha Vantage |

---

## API Endpoints

POST /api/v1/pipeline/run          # trigger pipeline
GET  /api/v1/pipeline/{run_id}     # status + partial results
GET  /api/v1/trace/{run_id}        # full Antigravity trace
GET  /api/v1/portfolio             # current state
GET  /api/v1/portfolio/history     # before/after snapshots
POST /api/v1/portfolio/reset       # reset to demo default
POST /api/v1/scenario/{name}       # load: oil_shock | rate_hike | earnings_beat
WS   /api/v1/stream                # live trace → Flutter UI


---

## UI Screens
| Screen | Judge Priority |
|---|---|
| Market Dashboard | High |
| *Agent Trace Screen* (live WebSocket stream) | *Critical* |
| *Trade Simulation Screen* (BEFORE/AFTER charts + risk gauge) | *Critical* |
| Insight Detail | High |
| Analytics / Notifications | Medium |

*Design:* Dark theme #0A0E1A · Buy #00D4AA · Sell #FF4560 · AI #7B61FF · Glassmorphism cards

---

## Demo Scenarios (pre-loaded)
| ID | Event | Expected Action | Risk Δ |
|---|---|---|---|
| oil_shock | Crude +18%, OPEC cut | SELL transport, BUY energy | HIGH→MEDIUM |
| rate_hike | Fed +75bps | SELL growth tech, BUY defensives | MEDIUM→LOW |
| earnings_beat | NVDA +40% earnings | BUY tech ETF, HOLD | LOW→LOW |

---

## Folder Structure

finagent/
├── backend/
│   ├── agents/
│   │   ├── base_agent.py
│   │   ├── input_intelligence.py
│   │   ├── market_context.py
│   │   ├── news_intelligence.py
│   │   ├── sentiment_analysis.py
│   │   ├── insight_extraction.py
│   │   ├── portfolio_risk.py
│   │   ├── decision.py
│   │   ├── trade_simulation.py
│   │   └── notification_viz.py
│   ├── orchestration/
│   │   ├── antigravity_client.py
│   │   ├── pipeline.py
│   │   └── context.py
│   ├── services/
│   │   ├── news_service.py
│   │   ├── rss_service.py
│   │   ├── stock_service.py
│   │   └── firebase_service.py
│   ├── data/
│   │   ├── mock_news_feed.json
│   │   ├── mock_social.json
│   │   ├── portfolio_default.json
│   │   └── scenarios/
│   │       ├── oil_shock.json
│   │       ├── rate_hike.json
│   │       └── earnings_beat.json
│   ├── models/schemas.py
│   ├── main.py
│   ├── requirements.txt
│   └── .env.example
├── frontend/
│   └── flutter_app/
│       ├── lib/
│       │   ├── screens/
│       │   │   ├── market_dashboard.dart
│       │   │   ├── agent_trace_screen.dart
│       │   │   ├── trade_simulation_screen.dart
│       │   │   ├── insight_detail_screen.dart
│       │   │   ├── analytics_screen.dart
│       │   │   └── notifications_screen.dart
│       │   ├── widgets/
│       │   │   ├── risk_gauge.dart
│       │   │   ├── portfolio_pie_chart.dart
│       │   │   ├── agent_trace_tile.dart
│       │   │   └── trade_log_table.dart
│       │   ├── services/
│       │   │   ├── api_service.dart
│       │   │   └── websocket_service.dart
│       │   └── main.dart
│       └── pubspec.yaml
├── FinAgent-core.md
├── FinAgent-core-compact.md
└── README.md


---

## Pre-Submission Checklist
- [ ] Pipeline completes with live APIs
- [ ] Pipeline completes fully offline (mock data)
- [ ] All agents emit reasoning_trace ≥ 3 entries
- [ ] Firebase BEFORE + AFTER snapshots written on every run
- [ ] Agent Trace Screen streams via WebSocket
- [ ] Portfolio sums to 100% post-execution
- [ ] All 3 scenarios run without error
- [ ] No hardcoded API keys in source