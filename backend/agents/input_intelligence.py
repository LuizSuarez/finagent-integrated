"""
Input Intelligence Agent — STEP 1
Collects and normalizes all incoming market data from:
  - NewsAPI
  - RSS Feeds
  - Mock Social Data
"""
import json
import asyncio
from datetime import datetime
from typing import Dict, Any

from agents.base_agent import BaseAgent
from models.schemas import AgentContract
from services.news_service import fetch_all_news
from services.stock_service import get_market_prices
from config import MOCK_SOCIAL


class InputIntelligenceAgent(BaseAgent):
    def __init__(self):
        super().__init__("Input Intelligence Agent")

    async def execute(self, context: Dict[str, Any]) -> AgentContract:
        start_time = datetime.now()
        reasoning = []
        
        trigger_event = context.get("trigger_event", {})
        scenario_data = trigger_event.get("scenario_data")

        # 1. Fetch news from all sources
        if scenario_data:
            from config import DATA_DIR
            reasoning.append(f"Scenario active. Bypassing live NewsAPI and loading mock news feed.")
            try:
                with open(DATA_DIR / "mock_news_feed.json", "r") as f:
                    news_items = json.load(f)
            except Exception as e:
                news_items = []
                reasoning.append(f"Error loading mock news: {e}")
        else:
            reasoning.append("Connecting to NewsAPI, Reuters RSS, Yahoo Finance RSS, and CNBC RSS feeds.")
            news_items = await fetch_all_news()
            
        reasoning.append(f"Collected {len(news_items)} unique financial news items after deduplication.")

        # 2. Load mock social signals
        social_signals = []
        try:
            with open(MOCK_SOCIAL, "r") as f:
                social_signals = json.load(f)
            reasoning.append(f"Loaded {len(social_signals)} social signals from mock dataset (X, Reddit).")
        except Exception as e:
            reasoning.append(f"Social data unavailable: {e}")

        # 3. Fetch real market prices via yfinance
        reasoning.append("Querying yfinance for live market prices: S&P 500, Oil/WTI, VIX.")
        market_prices = await get_market_prices()
        reasoning.append(
            f"Market snapshot: S&P {market_prices.get('SP500', 'N/A')}, "
            f"Oil ${market_prices.get('OIL_WTI', 'N/A')}, "
            f"VIX {market_prices.get('VIX', 'N/A')}."
        )

        total_signals = len(news_items) + len(social_signals)
        reasoning.append(
            f"Input processing complete. {total_signals} total signals normalized and ready for intelligence pipeline."
        )

        # Store results in context for downstream agents
        context["market_context"] = {
            "news_items": news_items,
            "social_signals": social_signals,
            "market_prices": market_prices,
            "total_signals": total_signals,
        }

        return self._create_contract(
            input_schema={"trigger": context.get("trigger_event", {})},
            output_schema={
                "news_items_count": len(news_items),
                "social_signals_count": len(social_signals),
                "market_prices": market_prices,
            },
            reasoning=reasoning,
            confidence=0.95 if len(news_items) > 2 else 0.70,
            start_time=start_time,
        )
