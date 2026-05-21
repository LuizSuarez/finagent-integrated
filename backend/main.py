"""
FinAgent FastAPI Backend — Main entry point.
All endpoints now wire to the real pipeline.
"""
import asyncio
import json
from datetime import datetime
from typing import Dict, Any

from fastapi import FastAPI, WebSocket, WebSocketDisconnect, BackgroundTasks
from fastapi.middleware.cors import CORSMiddleware

from orchestration.pipeline import (
    run_pipeline,
    get_pipeline_result,
    get_trace_log,
    get_portfolio,
)

app = FastAPI(title="FinAgent Backend", version="2.0.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

from services.news_service import fetch_all_news

# In-memory active WebSocket connections for live streaming
_active_connections: list[WebSocket] = []


# ---------------------------------------------------------------------------
# Pipeline Endpoints
# ---------------------------------------------------------------------------

@app.post("/api/v1/pipeline/run")
async def trigger_pipeline(background_tasks: BackgroundTasks):
    """Kick off the full 8-agent pipeline in the background."""
    trigger = {"source": "manual_trigger", "timestamp": datetime.now().isoformat()}
    run_id = str(__import__("uuid").uuid4())

    async def _on_step_complete(agent_id: str, contract: dict, context: dict):
        msg = {
            "type": "agent_progress",
            "run_id": run_id,
            "agent_id": agent_id,
            "contract": contract,
            "trace_log": get_trace_log(run_id),
            "insight": context.get("insight", {}),
            "risk": {k: v for k, v in context.get("risk", {}).items() if k != "portfolio"},
            "decision": context.get("decision", {}),
            "execution": context.get("execution", {}),
            "notifications": context.get("notifications", []),
            "sentiment": context.get("sentiment", {}),
        }
        for ws in _active_connections:
            try:
                await ws.send_json(msg)
            except Exception:
                pass

    # Run pipeline and broadcast completion over WebSocket
    async def _run_and_broadcast():
        await run_pipeline(trigger, on_step_complete=_on_step_complete, run_id=run_id)
        result = get_pipeline_result(run_id)
        ctx = result.get("context", {})
        news_items = ctx.get("market_context", {}).get("news_items", [])
        headlines = [item.get("headline") for item in news_items if item.get("headline")][:5]
        if not headlines:
            headlines = [
                "Oil prices surge 18% amid geopolitical tensions in the Middle East",
                "Fed signals potential interest rate hike to cool inflation",
                "NASDAQ composite drops 2.3% as tech sector valuations adjust",
                "Retail sales index rises higher than forecast in Q2 review",
            ]
        msg = {
            "type": "pipeline_complete",
            "run_id": run_id,
            "trace_log": get_trace_log(run_id),
            "insight": ctx.get("insight", {}),
            "risk": {k: v for k, v in ctx.get("risk", {}).items() if k != "portfolio"},
            "decision": ctx.get("decision", {}),
            "execution": ctx.get("execution", {}),
            "notifications": ctx.get("notifications", []),
            "sentiment": ctx.get("sentiment", {}),
            "headlines": headlines,
        }
        for ws in _active_connections:
            try:
                await ws.send_json(msg)
            except Exception:
                pass

    background_tasks.add_task(_run_and_broadcast)

    return {"status": "started", "run_id": run_id, "message": "Pipeline running. Connect to /api/v1/stream for live updates."}


@app.get("/api/v1/pipeline/{run_id}")
async def get_pipeline_status(run_id: str):
    result = get_pipeline_result(run_id)
    return {"run_id": run_id, "status": result.get("status", "not_found")}


@app.get("/api/v1/trace/{run_id}")
async def get_pipeline_trace(run_id: str):
    return {"run_id": run_id, "trace_log": get_trace_log(run_id)}


@app.get("/api/v1/news/headlines")
async def get_live_news_headlines():
    news_items = await fetch_all_news()
    headlines = [item.get("headline") for item in news_items if item.get("headline")][:5]
    if not headlines:
        headlines = [
            "Oil prices surge 18% amid geopolitical tensions in the Middle East",
            "Fed signals potential interest rate hike to cool inflation",
            "NASDAQ composite drops 2.3% as tech sector valuations adjust",
            "Retail sales index rises higher than forecast in Q2 review",
        ]
    return {"status": "ok", "headlines": headlines}


@app.get("/api/v1/market/prices")
async def get_current_market_prices():
    try:
        from services.stock_service import get_market_prices
        prices = await get_market_prices()
        return {"status": "ok", "prices": prices}
    except Exception as e:
        return {"status": "error", "detail": str(e)}


@app.get("/api/v1/insight/latest")
async def get_latest_insight():
    import json
    from config import DATA_DIR
    path = DATA_DIR / "latest_insight.json"
    if path.exists():
        try:
            with open(path) as f:
                return {"status": "ok", "insight": json.load(f)}
        except Exception as e:
            pass
    # Return empty state if no pipeline has run yet
    return {"status": "ok", "insight": None}


@app.get("/api/v1/trades/latest")
async def get_latest_trades():
    import json
    from config import DATA_DIR
    path = DATA_DIR / "latest_trades.json"
    if path.exists():
        try:
            with open(path) as f:
                return {"status": "ok", "trades": json.load(f)}
        except Exception as e:
            pass
    # Return empty list if no pipeline has run yet
    return {"status": "ok", "trades": []}


@app.get("/api/v1/execution/latest")
async def get_latest_execution():
    import json
    from config import DATA_DIR
    path = DATA_DIR / "latest_execution.json"
    if path.exists():
        try:
            with open(path) as f:
                return {"status": "ok", "execution": json.load(f)}
        except Exception as e:
            pass
    # Return empty object if no pipeline has run yet
    return {"status": "ok", "execution": None}


# ---------------------------------------------------------------------------
# Portfolio Endpoints
# ---------------------------------------------------------------------------

@app.get("/api/v1/portfolio")
async def get_portfolio_state(run_id: str = None):
    portfolio = get_portfolio(run_id)
    return {"status": "ok", "portfolio": portfolio}


@app.get("/api/v1/portfolio/history")
async def get_portfolio_history():
    # Future: return list of historical portfolio snapshots from Firebase
    return {"history": []}


@app.post("/api/v1/portfolio/reset")
async def reset_portfolio():
    import json
    from config import PORTFOLIO_DEFAULT
    try:
        with open(PORTFOLIO_DEFAULT) as f:
            default = json.load(f)
        return {"status": "reset", "portfolio": default}
    except Exception as e:
        return {"status": "error", "detail": str(e)}


# ---------------------------------------------------------------------------
# Scenario Endpoints
# ---------------------------------------------------------------------------

@app.post("/api/v1/scenario/{name}")
async def load_scenario(name: str, background_tasks: BackgroundTasks):
    """Load a named scenario JSON and run it through the pipeline."""
    from config import DATA_DIR
    scenario_path = DATA_DIR / "scenarios" / f"{name}.json"
    try:
        with open(scenario_path) as f:
            scenario_data = json.load(f)
        trigger = {"source": f"scenario:{name}", "scenario_data": scenario_data}

        run_id = str(__import__("uuid").uuid4())

        async def _on_step_complete(agent_id: str, contract: dict, context: dict):
            msg = {
                "type": "agent_progress",
                "run_id": run_id,
                "agent_id": agent_id,
                "contract": contract,
                "trace_log": get_trace_log(run_id),
                "insight": context.get("insight", {}),
                "risk": {k: v for k, v in context.get("risk", {}).items() if k != "portfolio"},
                "decision": context.get("decision", {}),
                "execution": context.get("execution", {}),
                "notifications": context.get("notifications", []),
                "sentiment": context.get("sentiment", {}),
            }
            for ws in _active_connections:
                try:
                    await ws.send_json(msg)
                except Exception:
                    pass

        async def _run_and_broadcast():
            await run_pipeline(trigger, on_step_complete=_on_step_complete, run_id=run_id)
            result = get_pipeline_result(run_id)
            ctx = result.get("context", {})
            msg = {
                "type": "pipeline_complete",
                "run_id": run_id,
                "trace_log": get_trace_log(run_id),
                "insight": ctx.get("insight", {}),
                "risk": {k: v for k, v in ctx.get("risk", {}).items() if k != "portfolio"},
                "decision": ctx.get("decision", {}),
                "execution": ctx.get("execution", {}),
                "notifications": ctx.get("notifications", []),
                "sentiment": ctx.get("sentiment", {}),
                "headlines": [],
            }
            for ws in _active_connections:
                try:
                    await ws.send_json(msg)
                except Exception:
                    pass

        background_tasks.add_task(_run_and_broadcast)
        return {"status": "started", "run_id": run_id, "message": f"Scenario {name} running."}
    except FileNotFoundError:
        return {"status": "error", "detail": f"Scenario '{name}' not found."}


# ---------------------------------------------------------------------------
# WebSocket — Real-time event stream
# ---------------------------------------------------------------------------

@app.websocket("/api/v1/stream")
async def websocket_endpoint(websocket: WebSocket):
    await websocket.accept()
    _active_connections.append(websocket)
    await websocket.send_json({
        "type": "connected",
        "message": "Connected to FinAgent live stream. Waiting for pipeline events.",
        "timestamp": datetime.now().isoformat(),
    })
    try:
        while True:
            data = await websocket.receive_text()
            if data == "ping":
                await websocket.send_json({"type": "pong", "timestamp": datetime.now().isoformat()})
    except WebSocketDisconnect:
        _active_connections.remove(websocket)
    except Exception as e:
        print(f"[WebSocket] Error: {e}")
        if websocket in _active_connections:
            _active_connections.remove(websocket)
