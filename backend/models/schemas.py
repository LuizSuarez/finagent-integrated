from pydantic import BaseModel, Field
from typing import List, Dict, Any, Optional
from datetime import datetime

class AgentContract(BaseModel):
    agent_id: str
    input_schema: Dict[str, Any]
    output_schema: Dict[str, Any]
    reasoning_trace: List[str]
    confidence_score: float
    execution_time_ms: int
    fallback_triggered: bool = False

class TradeLog(BaseModel):
    trade_id: str
    timestamp: datetime
    action: str  # "BUY" or "SELL"
    asset: str
    quantity: float
    mock_price: float
    slippage_applied_pct: float
    status: str = "EXECUTED"

class AssetHolding(BaseModel):
    allocation_pct: float
    value: float

class PortfolioSnapshot(BaseModel):
    snapshot_id: str
    holdings: Dict[str, AssetHolding]
    risk_level: str
    risk_score: float

class PipelineContext(BaseModel):
    run_id: str
    trigger_event: Dict[str, Any] = {}
    market_context: Dict[str, Any] = {}
    sentiment: Dict[str, Any] = {}
    insight: Dict[str, Any] = {}
    risk: Dict[str, Any] = {}
    decision: Dict[str, Any] = {}
    execution: Dict[str, Any] = {}
    trace_log: List[AgentContract] = []
    started_at: datetime
    completed_at: Optional[datetime] = None
