"""
Insight Extraction Agent — STEP 4
Combines news intelligence + sentiment + market prices
to generate a single actionable market insight using Gemini AI.
"""
import asyncio
from datetime import datetime
from typing import Dict, Any

from agents.base_agent import BaseAgent
from models.schemas import AgentContract
from services.gemini_service import generate_insight


class InsightExtractionAgent(BaseAgent):
    def __init__(self):
        super().__init__("Insight Extraction Agent")

    async def execute(self, context: Dict[str, Any]) -> AgentContract:
        start_time = datetime.now()
        reasoning = []

        sentiment = context.get("sentiment", {})
        news_intel = context.get("news_intelligence", {})
        market_prices = context.get("market_context", {}).get("market_prices", {})

        reasoning.append(
            "Synthesizing news intelligence, sentiment scores, and live market prices "
            "into a single actionable insight."
        )
        reasoning.append(
            f"Input signals: sentiment={sentiment.get('score', 0):.3f} ({sentiment.get('label')}), "
            f"key_event='{news_intel.get('key_event', 'N/A')}', "
            f"Oil=${market_prices.get('OIL_WTI', 'N/A')}, VIX={market_prices.get('VIX', 'N/A')}."
        )

        reasoning.append("Invoking Gemini AI insight synthesis engine.")
        insight = await generate_insight(sentiment, news_intel, market_prices)

        summary = insight.get("summary", "Market volatility detected; portfolio review recommended.")
        severity = insight.get("severity", "MEDIUM")
        sector_focus = insight.get("sector_focus", "transportation")
        confidence = float(insight.get("confidence", 0.85))
        tags = insight.get("tags", ["market_risk", "volatility"])

        reasoning.append(f"Core insight generated — Severity: {severity}. Sector focus: '{sector_focus}'.")
        reasoning.append(
            f"Gemini AI confidence: {int(confidence * 100)}%. "
            f"Signal tags extracted: {tags}."
        )

        context["insight"] = {
            "summary": summary,
            "severity": severity,
            "sector_focus": sector_focus,
            "confidence": confidence,
            "tags": tags,
            "affected_negative_sectors": news_intel.get("affected_negative", []),
            "affected_positive_sectors": news_intel.get("affected_positive", []),
            "sentiment_score": sentiment.get("score", 0),
        }

        return self._create_contract(
            input_schema={
                "sentiment_score": sentiment.get("score"),
                "key_event": news_intel.get("key_event"),
            },
            output_schema=context["insight"],
            reasoning=reasoning,
            confidence=confidence,
            start_time=start_time,
        )
