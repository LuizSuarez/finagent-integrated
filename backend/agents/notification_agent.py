"""
Notification Agent — STEP 8 (Final)
Formats execution results into user-facing notification payloads
and logs them to Firebase (or console in mock mode).
"""
from datetime import datetime
from typing import Dict, Any, List

from agents.base_agent import BaseAgent
from models.schemas import AgentContract
from services.firebase_service import FirebaseService

_firebase = FirebaseService()


class NotificationAgent(BaseAgent):
    def __init__(self):
        super().__init__("Notification Agent")

    async def execute(self, context: Dict[str, Any]) -> AgentContract:
        start_time = datetime.now()
        reasoning = []

        risk = context.get("risk", {})
        decision = context.get("decision", {})
        execution = context.get("execution", {})
        insight = context.get("insight", {})

        risk_level = risk.get("risk_level", "HIGH")
        risk_delta = decision.get("risk_delta", "HIGH → MEDIUM")
        trade_count = execution.get("trade_count", 0)
        trades = execution.get("trades", [])
        expected_loss = risk.get("expected_loss", 0)
        insight_summary = insight.get("summary", "Market analysis complete.")

        reasoning.append(
            f"Composing notifications for completed pipeline run. "
            f"{trade_count} trade(s) executed. Risk transition: {risk_delta}."
        )

        notifications: List[Dict[str, Any]] = []
        now_str = datetime.now().strftime("%H:%M:%S")

        # 1 — Risk elevation alert
        notifications.append({
            "id": f"notif_risk_{now_str}",
            "icon": "error_outline",
            "title": f"Portfolio risk elevated to {risk_level}",
            "body": (
                f"High sector vulnerability detected. "
                f"Projected downside: ${expected_loss:,.0f}. "
                f"Immediate rebalancing recommended."
            ),
            "severity": "CRITICAL" if risk_level in ("HIGH", "CRITICAL") else "WARNING",
            "timestamp": now_str,
            "is_unread": True,
        })

        # 2 — Trade execution confirmation (one per trade)
        for trade in trades:
            action = trade.get("action", "TRADE")
            asset = trade.get("asset", "ASSET")
            qty = trade.get("quantity", 0)
            price = trade.get("exec_price", 0)
            notifications.append({
                "id": f"notif_trade_{trade.get('trade_id', '')}",
                "icon": "swap_horizontal_circle",
                "title": f"{action} order executed — {asset}",
                "body": f"{qty} units @ ${price:.2f}. Order settled via liquidity pool.",
                "severity": "INFO",
                "timestamp": trade.get("timestamp", now_str),
                "is_unread": True,
            })

        # 3 — Risk mitigation success
        notifications.append({
            "id": f"notif_complete_{now_str}",
            "icon": "check_circle_outline",
            "title": "Agent workflow complete",
            "body": (
                f"FinAgent analyzed market impact and executed {trade_count} rebalancing trades. "
                f"Risk transition: {risk_delta}. Portfolio now more defensively positioned."
            ),
            "severity": "INFO",
            "timestamp": now_str,
            "is_unread": False,
        })

        # 4 — Core insight notification
        notifications.append({
            "id": f"notif_insight_{now_str}",
            "icon": "lightbulb_outline",
            "title": f"Market insight — {insight.get('severity', 'MEDIUM')} severity",
            "body": insight_summary[:200],
            "severity": "WARNING",
            "timestamp": now_str,
            "is_unread": True,
        })

        reasoning.append(f"Generated {len(notifications)} notification payloads.")

        # Log trades to Firebase
        for trade in trades:
            await _firebase.log_trade(trade)

        # Save portfolio snapshot to Firebase
        portfolio_after = execution.get("portfolio_after", {})
        if portfolio_after:
            import uuid
            snapshot_id = str(uuid.uuid4())[:8].upper()
            snapshot = {
                "snapshot_id": f"snap_{snapshot_id}",
                "timestamp": datetime.now().isoformat(),
                "holdings": portfolio_after,
                "total_value": execution.get("total_value_after", 0.0),
                "risk_level": risk_delta.split("→")[-1].strip(),
            }
            await _firebase.save_portfolio_snapshot(snapshot)

        reasoning.append(
            f"Trade logs and portfolio snapshots dispatched to Firebase. "
            f"Portfolio rebalanced: {risk_delta}. System state updated."
        )

        context["notifications"] = notifications

        return self._create_contract(
            input_schema={"trade_count": trade_count, "risk_delta": risk_delta},
            output_schema={"notification_count": len(notifications)},
            reasoning=reasoning,
            confidence=0.99,
            start_time=start_time,
        )
