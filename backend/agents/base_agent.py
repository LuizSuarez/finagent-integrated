from abc import ABC, abstractmethod
from typing import Dict, Any, List
from datetime import datetime
from models.schemas import AgentContract

class BaseAgent(ABC):
    def __init__(self, agent_id: str):
        self.agent_id = agent_id

    @abstractmethod
    async def execute(self, context: Dict[str, Any]) -> AgentContract:
        pass

    def _create_contract(self, input_schema: dict, output_schema: dict, reasoning: List[str], confidence: float, start_time: datetime) -> AgentContract:
        exec_time = int((datetime.now() - start_time).total_seconds() * 1000)
        return AgentContract(
            agent_id=self.agent_id,
            input_schema=input_schema,
            output_schema=output_schema,
            reasoning_trace=reasoning,
            confidence_score=confidence,
            execution_time_ms=exec_time,
            fallback_triggered=confidence < 0.65
        )
