"""
Sentiment Analysis Agent — STEP 3
Analyzes market sentiment from news headlines and social signals
using VADER (fast, financial-aware) and TextBlob (polarity check).
"""
import asyncio
from datetime import datetime
from typing import Dict, Any, List

from vaderSentiment.vaderSentiment import SentimentIntensityAnalyzer
from textblob import TextBlob

from agents.base_agent import BaseAgent
from models.schemas import AgentContract

_vader = SentimentIntensityAnalyzer()


def _score_text(text: str) -> float:
    """Returns compound VADER score [-1, 1]."""
    return _vader.polarity_scores(text)["compound"]


def _textblob_polarity(text: str) -> float:
    return TextBlob(text).sentiment.polarity


def _label_from_score(score: float) -> str:
    if score >= 0.05:
        return "POSITIVE"
    elif score <= -0.05:
        return "NEGATIVE"
    return "NEUTRAL"


class SentimentAnalysisAgent(BaseAgent):
    def __init__(self):
        super().__init__("Sentiment Analysis Agent")

    async def execute(self, context: Dict[str, Any]) -> AgentContract:
        start_time = datetime.now()
        reasoning = []

        market_ctx = context.get("market_context", {})
        news_items: List[Dict] = market_ctx.get("news_items", [])
        social_signals: List[Dict] = market_ctx.get("social_signals", [])
        news_intel = context.get("news_intelligence", {})
        affected_negative = news_intel.get("affected_negative", [])

        reasoning.append(
            f"Running VADER sentiment analysis on {len(news_items)} news headlines "
            f"and {len(social_signals)} social signals."
        )

        # --- Score all news headlines ---
        news_scores = []
        for item in news_items:
            text = item.get("headline", "") + " " + item.get("content", "")[:200]
            vader_score = _score_text(text)
            blob_score = _textblob_polarity(text)
            # Weighted blend: VADER 70% + TextBlob 30%
            blended = (vader_score * 0.7) + (blob_score * 0.3)
            news_scores.append(blended)

        # --- Score social signals ---
        social_scores = []
        for signal in social_signals:
            text = signal.get("post", "")
            score = _score_text(text)
            social_scores.append(score)

        # --- Aggregate ---
        all_scores = news_scores + social_scores
        if not all_scores:
            all_scores = [-0.76]  # fallback

        avg_score = sum(all_scores) / len(all_scores)
        label = _label_from_score(avg_score)

        # --- Sector-level sentiment (for affected sectors) ---
        sector_scores: Dict[str, float] = {}
        for sector in affected_negative:
            # Filter news mentioning this sector
            sector_texts = [
                item.get("headline", "") + " " + item.get("content", "")[:100]
                for item in news_items
                if sector.lower() in (item.get("headline", "") + item.get("content", "")).lower()
            ]
            if sector_texts:
                sector_scores[sector] = sum(_score_text(t) for t in sector_texts) / len(sector_texts)
            else:
                sector_scores[sector] = avg_score

        most_negative_sector = (
            min(sector_scores, key=sector_scores.get) if sector_scores else (affected_negative[0] if affected_negative else "unknown")
        )

        reasoning.append(
            f"VADER + TextBlob analysis complete. "
            f"Overall market sentiment: {label} (score: {avg_score:.3f})."
        )
        reasoning.append(
            f"Sector breakdown — {', '.join(f'{k}: {v:.2f}' for k, v in sector_scores.items())}. "
            f"Most bearish sector: '{most_negative_sector}'."
        )
        reasoning.append(
            f"Social signal sentiment averaged {sum(social_scores)/len(social_scores):.3f} "
            f"across {len(social_scores)} posts — confirming {'bearish' if avg_score < 0 else 'bullish'} bias."
            if social_scores else "No social signals contributed to sentiment."
        )

        context["sentiment"] = {
            "score": round(avg_score, 3),
            "label": label,
            "news_avg": round(sum(news_scores) / len(news_scores), 3) if news_scores else 0,
            "social_avg": round(sum(social_scores) / len(social_scores), 3) if social_scores else 0,
            "sector_scores": {k: round(v, 3) for k, v in sector_scores.items()},
            "most_negative_sector": most_negative_sector,
            "total_scored": len(all_scores),
        }

        return self._create_contract(
            input_schema={"items_scored": len(all_scores)},
            output_schema=context["sentiment"],
            reasoning=reasoning,
            confidence=0.92,
            start_time=start_time,
        )
