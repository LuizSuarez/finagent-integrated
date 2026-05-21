"""
Decision Agent — STEP 6
Evaluates risk assessment and insight to generate
autonomous trade decisions using Gemini AI reasoning.
"""
from datetime import datetime
from typing import Dict, Any, List

from agents.base_agent import BaseAgent
from models.schemas import AgentContract
from services.gemini_service import generate_decision


class DecisionAgent(BaseAgent):
    def __init__(self):
        super().__init__("Decision Agent")

    async def execute(self, context: Dict[str, Any]) -> AgentContract:
        start_time = datetime.now()
        reasoning = []

        risk = context.get("risk", {})
        insight = context.get("insight", {})
        portfolio = risk.get("portfolio", {})

        risk_level = risk.get("risk_level", "HIGH")
        expected_loss = risk.get("expected_loss", 0)
        most_exposed = risk.get("most_exposed_asset", "N/A")
        severity = insight.get("severity", "HIGH")

        reasoning.append(
            f"Evaluating risk profile: {risk_level} risk, ${expected_loss:,.0f} projected loss. "
            f"Most exposed asset: '{most_exposed}'."
        )
        reasoning.append(
            f"Insight severity: {severity}. "
            f"Positive sectors to rotate into: {insight.get('affected_positive_sectors', [])}."
        )

        # Invoke Gemini for decision reasoning
        reasoning.append("Invoking Gemini AI autonomous decision engine to determine optimal rebalancing strategy.")
        decision = await generate_decision(risk, insight, portfolio)

        actions: List[Dict] = decision.get("actions", [
            {"type": "SELL", "asset": "FDX", "target_pct": 15.0, "reason": "High fuel cost exposure"},
            {"type": "BUY",  "asset": "XOM", "target_pct": 40.0, "reason": "Oil price hedge"},
        ])
        decision_reasoning = decision.get("reasoning", "Reducing high-risk exposure and rotating into benefiting sectors.")
        confidence = float(decision.get("confidence", 0.88))
        risk_delta = decision.get("risk_delta", f"{risk_level} → MEDIUM")

        for action in actions:
            reasoning.append(
                f"Action approved: {action['type']} '{action['asset']}' "
                f"→ target allocation {action.get('target_pct', '?')}%. "
                f"Rationale: {action.get('reason', '')}."
            )

        reasoning.append(
            f"Decision confidence: {int(confidence * 100)}%. "
            f"Expected risk transition: {risk_delta}."
        )

        context["decision"] = {
            "actions": actions,
            "reasoning": decision_reasoning,
            "confidence": confidence,
            "risk_delta": risk_delta,
            "action_count": len(actions),
        }

        return self._create_contract(
            input_schema={"risk_level": risk_level, "severity": severity},
            output_schema=context["decision"],
            reasoning=reasoning,
            confidence=confidence,
            start_time=start_time,
        )
