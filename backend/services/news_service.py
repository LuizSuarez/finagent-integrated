"""
News Service — Fetches financial news with a cascading fallback strategy:
  1. NewsAPI (if key available)
  2. RSS feeds (always free)
  3. Local mock dataset (guaranteed fallback)
"""
import json
import requests
from typing import List, Dict, Any
from datetime import datetime

from config import NEWSAPI_KEY, USE_REAL_NEWS, MOCK_NEWS
from services.rss_service import fetch_rss_news


# ---------------------------------------------------------------------------
# NewsAPI
# ---------------------------------------------------------------------------
NEWSAPI_URL = "https://newsapi.org/v2/everything"
NEWSAPI_PARAMS = {
    "q": "oil OR market OR inflation OR OPEC OR logistics OR economy OR stocks",
    "language": "en",
    "sortBy": "publishedAt",
    "pageSize": 20,
}


def _fetch_newsapi() -> List[Dict[str, Any]]:
    """Call NewsAPI synchronously."""
    try:
        resp = requests.get(
            NEWSAPI_URL,
            params={**NEWSAPI_PARAMS, "apiKey": NEWSAPI_KEY},
            timeout=8,
        )
        resp.raise_for_status()
        articles = resp.json().get("articles", [])
        return [
            {
                "id": f"napi_{i}",
                "headline": a.get("title", ""),
                "content": a.get("description", "") or a.get("content", ""),
                "source": a.get("source", {}).get("name", "NewsAPI"),
                "url": a.get("url", ""),
                "timestamp": a.get("publishedAt", datetime.utcnow().isoformat()),
            }
            for i, a in enumerate(articles)
            if a.get("title") and "[Removed]" not in a.get("title", "")
        ]
    except Exception as e:
        print(f"[NewsService] NewsAPI error: {e}")
        return []


def _load_mock_news() -> List[Dict[str, Any]]:
    """Load the local mock news JSON as guaranteed fallback."""
    try:
        with open(MOCK_NEWS, "r") as f:
            return json.load(f)
    except Exception as e:
        print(f"[NewsService] Mock news load error: {e}")
        return []


async def fetch_all_news() -> List[Dict[str, Any]]:
    """
    Cascade strategy:
      NewsAPI → RSS feeds → Mock
    Merges results from all available sources.
    """
    all_items: List[Dict[str, Any]] = []
    seen = set()

    # 1. NewsAPI
    if USE_REAL_NEWS:
        newsapi_items = _fetch_newsapi()
        for item in newsapi_items:
            key = item["headline"][:60].lower()
            if key not in seen:
                seen.add(key)
                all_items.append(item)
        print(f"[NewsService] NewsAPI returned {len(newsapi_items)} items")

    # 2. RSS feeds (always attempted)
    try:
        rss_items = await fetch_rss_news()
        for item in rss_items:
            key = item["headline"][:60].lower()
            if key not in seen:
                seen.add(key)
                all_items.append(item)
        print(f"[NewsService] RSS returned {len(rss_items)} items")
    except Exception as e:
        print(f"[NewsService] RSS failed: {e}")

    # 3. Mock fallback — always add if we have very little
    if len(all_items) < 3:
        mock_items = _load_mock_news()
        for item in mock_items:
            key = item.get("headline", "")[:60].lower()
            if key not in seen:
                seen.add(key)
                all_items.append(item)
        print(f"[NewsService] Loaded {len(mock_items)} mock items as fallback")

    print(f"[NewsService] Total unique news items: {len(all_items)}")
    return all_items
