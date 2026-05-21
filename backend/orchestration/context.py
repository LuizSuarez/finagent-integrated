import uuid
from datetime import datetime
from typing import Dict, Any

def create_initial_context(trigger_event: Dict[str, Any], run_id: str = None) -> Dict[str, Any]:
    """Initialize the shared Antigravity PipelineContext."""
    if not run_id:
        run_id = str(uuid.uuid4())
    
    return {
        "run_id": run_id,
        "trigger_event": trigger_event,
        "started_at": datetime.now().isoformat(),
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
