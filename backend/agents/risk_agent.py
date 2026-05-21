"""
Portfolio Risk Agent — STEP 5
Evaluates portfolio holdings against the market insight
to calculate exposure, risk score, and expected loss.
"""
import json
from datetime import datetime
from typing import Dict, Any, List

from agents.base_agent import BaseAgent
from models.schemas import AgentContract
from config import PORTFOLIO_DEFAULT

ASSET_SECTOR_MAP: Dict[str, List[str]] = {
    "transportation": ["FDX"],
    "logistics":      ["FDX"],
    "airlines":       ["FDX"],
    "energy":         ["XOM"],
    "oil_etfs":       ["XOM"],
    "technology":     ["AAPL", "VTI"],
    "finance":        ["VTI"],
}

SEVERITY_MULTIPLIERS = {"LOW": 0.3, "MEDIUM": 0.5, "HIGH": 0.8, "CRITICAL": 1.0}


def _risk_label(score: float) -> str:
    if score < 0.30: return "LOW"
    if score < 0.55: return "MEDIUM"
    if score < 0.80: return "HIGH"
    return "CRITICAL"


def _load_portfolio() -> Dict[str, Any]:
    try:
        with open(PORTFOLIO_DEFAULT, "r") as f:
            return json.load(f)
    except Exception:
        return {
            "snapshot_id": "default_001",
            "risk_level": "LOW",
            "risk_score": 0.25,
            "holdings": {
                "FDX":  {"allocation_pct": 35.0, "value": 35000.0},
                "XOM":  {"allocation_pct": 20.0, "value": 20000.0},
                "AAPL": {"allocation_pct": 30.0, "value": 30000.0},
                "CASH": {"allocation_pct": 15.0, "value": 15000.0},
            }
        }


class PortfolioRiskAgent(BaseAgent):
    def __init__(self):
        super().__init__("Portfolio Risk Agent")

    async def execute(self, context: Dict[str, Any]) -> AgentContract:
        start_time = datetime.now()
        reasoning = []

        insight = context.get("insight", {})
        sentiment = context.get("sentiment", {})
        affected_negative = insight.get("affected_negative_sectors", ["transportation"])
        severity = insight.get("severity", "HIGH")

        portfolio = _load_portfolio()
        holdings = portfolio.get("holdings", {})
        total_value = sum(h.get("value", 0) for h in holdings.values())

        reasoning.append(
            f"Loaded portfolio: {len(holdings)} holdings, total value ${total_value:,.0f}."
        )

        # Identify exposed assets
        seen_assets = set()
        exposed_assets = []
        for sector in affected_negative:
            for asset in ASSET_SECTOR_MAP.get(sector.lower(), []):
                if asset in holdings and asset not in seen_assets:
                    seen_assets.add(asset)
                    exposed_assets.append({
                        "asset": asset,
                        "sector": sector,
                        "allocation_pct": holdings[asset]["allocation_pct"],
                        "value": holdings[asset]["value"],
                    })

        total_exposed_pct = sum(e["allocation_pct"] for e in exposed_assets)
        total_exposed_value = sum(e["value"] for e in exposed_assets)

        reasoning.append(
            f"Exposure scan: {[e['asset'] for e in exposed_assets]} at risk. "
            f"Total exposure: {total_exposed_pct:.1f}% (${total_exposed_value:,.0f})."
        )

        # Risk score
        sentiment_factor = max(0.1, min(1.0, abs(sentiment.get("score", 0.5))))
        exposure_factor = total_exposed_pct / 100.0
        risk_score = min(0.99, exposure_factor * SEVERITY_MULTIPLIERS.get(severity, 0.7) * (0.7 + 0.3 * sentiment_factor))
        risk_level = _risk_label(risk_score)

        drawdown = 0.20 if severity in ("HIGH", "CRITICAL") else 0.10
        expected_loss = total_exposed_value * drawdown
        most_exposed = max(exposed_assets, key=lambda x: x["allocation_pct"])["asset"] if exposed_assets else "N/A"

        reasoning.append(
            f"Risk score: {risk_score:.2f} → {risk_level}. "
            f"Most exposed: '{most_exposed}'. Estimated loss: ${expected_loss:,.0f}."
        )

        context["risk"] = {
            "risk_level": risk_level,
            "risk_score": round(risk_score, 3),
            "exposed_assets": exposed_assets,
            "total_exposed_pct": round(total_exposed_pct, 1),
            "total_exposed_value": round(total_exposed_value, 2),
            "expected_loss": round(expected_loss, 2),
            "most_exposed_asset": most_exposed,
            "portfolio": portfolio,
        }

        return self._create_contract(
            input_schema={"holdings_count": len(holdings), "severity": severity},
            output_schema={k: v for k, v in context["risk"].items() if k != "portfolio"},
            reasoning=reasoning,
            confidence=0.89,
            start_time=start_time,
        )
