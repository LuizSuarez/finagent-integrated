"""
Pipeline Orchestrator — Runs all agents in sequence,
passing shared context between them and streaming progress.
"""
import uuid
from datetime import datetime
from typing import Dict, Any, AsyncGenerator

from orchestration.context import create_initial_context
from orchestration.antigravity_client import AntigravityClient
from models.schemas import PipelineContext
from agents.input_intelligence import InputIntelligenceAgent
from agents.news_agent import NewsIntelligenceAgent
from agents.sentiment_agent import SentimentAnalysisAgent
from agents.insight_agent import InsightExtractionAgent
from agents.risk_agent import PortfolioRiskAgent
from agents.decision_agent import DecisionAgent
from agents.execution_agent import TradeSimulationAgent
from agents.notification_agent import NotificationAgent

# In-memory store keyed by run_id
_pipeline_results: Dict[str, Dict[str, Any]] = {}


def _build_agents():
    return [
        InputIntelligenceAgent(),
        NewsIntelligenceAgent(),
        SentimentAnalysisAgent(),
        InsightExtractionAgent(),
        PortfolioRiskAgent(),
        DecisionAgent(),
        TradeSimulationAgent(),
        NotificationAgent(),
    ]


async def run_pipeline(trigger_event: Dict[str, Any], on_step_complete=None, run_id: str = None) -> str:
    """
    Run the full agent pipeline using Google Antigravity orchestration.
    """
    context = create_initial_context(trigger_event, run_id)
    run_id = context["run_id"]

    _pipeline_results[run_id] = {"status": "running", "context": context}

    agents = _build_agents()
    client = AntigravityClient(agents, on_step_complete)
    await client.orchestrate(context)

    context["completed_at"] = datetime.now().isoformat()
    _pipeline_results[run_id]["status"] = "completed"

    import json
    from config import DATA_DIR
    try:
        with open(DATA_DIR / "latest_insight.json", "w") as f:
            json.dump(context.get("insight", {}), f)
        with open(DATA_DIR / "latest_trades.json", "w") as f:
            json.dump(context.get("execution", {}).get("trades", []), f)
        with open(DATA_DIR / "latest_execution.json", "w") as f:
            json.dump(context.get("execution", {}), f)
    except Exception as e:
        print(f"[Pipeline] Failed to save latest context: {e}")

    return run_id


def get_pipeline_result(run_id: str) -> Dict[str, Any]:
    return _pipeline_results.get(run_id, {"status": "not_found"})


def get_trace_log(run_id: str):
    result = _pipeline_results.get(run_id)
    if not result:
        return []
    return result.get("context", {}).get("trace_log", [])


def get_portfolio(run_id: str = None):
    """Return portfolio state — after rebalance if run_id provided."""
    if run_id and run_id in _pipeline_results:
        ctx = _pipeline_results[run_id].get("context", {})
        execution = ctx.get("execution", {})
        if execution.get("portfolio_after"):
            return execution["portfolio_after"]
    # Return default portfolio
    import json
    from config import PORTFOLIO_DEFAULT
    try:
        with open(PORTFOLIO_DEFAULT) as f:
            return json.load(f)
    except Exception:
        return {}
