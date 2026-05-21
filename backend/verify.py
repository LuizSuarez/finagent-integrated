"""
FinAgent Backend — Verification Script (Windows Safe ASCII Edition)
Run this to confirm all components are working before starting the server.
Usage: python verify.py
"""
import asyncio
import sys
import os

# Make sure we run from the backend directory
os.chdir(os.path.dirname(os.path.abspath(__file__)))

# ASCII safe markers
PASS = "[ OK ]"
FAIL = "[FAIL]"
WARN = "[WARN]"

results = []

def report(label: str, ok: bool, detail: str = ""):
    icon = PASS if ok else FAIL
    results.append(ok)
    print(f"  {icon} {label}" + (f" - {detail}" if detail else ""))


# ─────────────────────────────────────────────
# 1. Config & API Keys
# ─────────────────────────────────────────────
print("\n== 1. Config & API Keys ======================")
try:
    from config import GEMINI_API_KEY, NEWSAPI_KEY, USE_REAL_LLM, USE_REAL_NEWS
    report("Config loads",          True)
    report("Gemini API key set",    bool(GEMINI_API_KEY), GEMINI_API_KEY[:8] + "..." if GEMINI_API_KEY else "MISSING")
    report("NewsAPI key set",       bool(NEWSAPI_KEY),    NEWSAPI_KEY[:8] + "..." if NEWSAPI_KEY else "MISSING")
    report("USE_REAL_LLM flag",     USE_REAL_LLM,  str(USE_REAL_LLM))
    report("USE_REAL_NEWS flag",    USE_REAL_NEWS, str(USE_REAL_NEWS))
except Exception as e:
    report("Config loads", False, str(e))


# ─────────────────────────────────────────────
# 2. Schemas
# ─────────────────────────────────────────────
print("\n== 2. Pydantic Schemas ========================")
try:
    from models.schemas import AgentContract, PipelineContext, TradeLog, PortfolioSnapshot
    report("AgentContract",     True)
    report("PipelineContext",   True)
    report("TradeLog",          True)
    report("PortfolioSnapshot", True)
except Exception as e:
    report("Schemas import", False, str(e))


# ─────────────────────────────────────────────
# 3. Services
# ─────────────────────────────────────────────
print("\n== 3. Services ================================")

async def test_services():
    # --- Stock Service ---
    try:
        from services.stock_service import get_market_prices
        prices = await get_market_prices()
        oil = prices.get("OIL_WTI", 0)
        report("Stock service (yfinance)", oil > 0, f"Oil/WTI=${oil:.2f}")
    except Exception as e:
        report("Stock service", False, str(e))

    # --- RSS Service ---
    try:
        from services.rss_service import fetch_rss_news
        items = await fetch_rss_news()
        report("RSS service", len(items) >= 0, f"{len(items)} articles fetched")
    except Exception as e:
        report("RSS service", False, str(e))

    # --- News Service ---
    try:
        from services.news_service import fetch_all_news
        news = await fetch_all_news()
        report("News service (cascade)", len(news) > 0, f"{len(news)} unique articles")
    except Exception as e:
        report("News service", False, str(e))

    # --- Gemini Service ---
    try:
        from services.gemini_service import analyze_news_intelligence
        result = await analyze_news_intelligence(
            [{"headline": "Oil prices surge 18% amid OPEC cuts", "content": "Fuel costs rise."}],
            [{"platform": "X", "post": "Transportation stocks tanking!"}]
        )
        has_event = "key_event" in result
        report("Gemini service", has_event, result.get("key_event", "")[:60])
    except Exception as e:
        report("Gemini service", False, str(e))

try:
    asyncio.run(test_services())
except Exception as e:
    print(f"Error running service tests: {e}")


# ─────────────────────────────────────────────
# 4. Agent Contract Check
# ─────────────────────────────────────────────
print("\n== 4. Individual Agents =======================")

async def test_agents():
    context = {
        "run_id": "test_001",
        "trigger_event": {"source": "verify_script"},
        "trace_log": [],
        "market_context": {},
        "news_intelligence": {},
        "sentiment": {},
        "insight": {},
        "risk": {},
        "decision": {},
        "execution": {},
        "notifications": [],
    }

    agent_classes = [
        ("InputIntelligenceAgent", "agents.input_intelligence", "InputIntelligenceAgent"),
        ("NewsIntelligenceAgent",  "agents.news_agent",         "NewsIntelligenceAgent"),
        ("SentimentAnalysisAgent", "agents.sentiment_agent",    "SentimentAnalysisAgent"),
        ("InsightExtractionAgent", "agents.insight_agent",      "InsightExtractionAgent"),
        ("PortfolioRiskAgent",     "agents.risk_agent",         "PortfolioRiskAgent"),
        ("DecisionAgent",          "agents.decision_agent",     "DecisionAgent"),
        ("TradeSimulationAgent",   "agents.execution_agent",    "TradeSimulationAgent"),
        ("NotificationAgent",      "agents.notification_agent", "NotificationAgent"),
    ]

    for label, module_path, class_name in agent_classes:
        try:
            import importlib
            mod = importlib.import_module(module_path)
            cls = getattr(mod, class_name)
            agent = cls()
            contract = await agent.execute(context)
            confidence = contract.confidence_score
            exec_ms = contract.execution_time_ms
            report(label, True, f"confidence={confidence:.2f}, {exec_ms}ms")
        except Exception as e:
            report(label, False, str(e)[:80])

try:
    asyncio.run(test_agents())
except Exception as e:
    print(f"Error running agent tests: {e}")


# ─────────────────────────────────────────────
# 5. Full Pipeline End-to-End
# ─────────────────────────────────────────────
print("\n== 5. Full Pipeline E2E =======================")

async def test_pipeline():
    try:
        from orchestration.pipeline import run_pipeline, get_pipeline_result, get_trace_log
        run_id = await run_pipeline({"source": "verify_script"})
        result = get_pipeline_result(run_id)
        trace = get_trace_log(run_id)
        ctx = result.get("context", {})

        report("Pipeline runs",           result.get("status") == "completed", f"run_id={run_id[:8]}")
        report("Trace log populated",     len(trace) == 8, f"{len(trace)}/8 agents logged")
        report("Insight generated",       bool(ctx.get("insight", {}).get("summary")), ctx.get("insight", {}).get("severity", "N/A"))
        report("Risk assessed",           bool(ctx.get("risk", {}).get("risk_level")),  ctx.get("risk", {}).get("risk_level", "N/A"))
        report("Decisions made",          bool(ctx.get("decision", {}).get("actions")), f"{len(ctx.get('decision', {}).get('actions', []))} actions")
        report("Trades executed",         bool(ctx.get("execution", {}).get("trades")), f"{ctx.get('execution', {}).get('trade_count', 0)} trades")
        report("Notifications generated", bool(ctx.get("notifications")),               f"{len(ctx.get('notifications', []))} notifications")
    except Exception as e:
        report("Pipeline E2E", False, str(e))

try:
    asyncio.run(test_pipeline())
except Exception as e:
    print(f"Error running pipeline tests: {e}")


# ─────────────────────────────────────────────
# Summary
# ─────────────────────────────────────────────
print("\n" + "=" * 50)
passed = sum(results)
total  = len(results)
pct    = int(passed / total * 100) if total else 0
print(f"  Result: {passed}/{total} checks passed ({pct}%)")
if passed == total:
    print("  All checks passed! Run: uvicorn main:app --reload --port 8000")
else:
    failed = total - passed
    print(f"  {failed} check(s) failed. Fix above before starting server.")
print("=" * 50 + "\n")
sys.exit(0 if passed == total else 1)
