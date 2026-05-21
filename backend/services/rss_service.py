"""
RSS Service — Fetches and parses financial RSS feeds.
Free, no API key required.
"""
import feedparser
import asyncio
from datetime import datetime
from typing import List, Dict, Any

RSS_SOURCES = [
    {
        "name": "Reuters Business",
        "url": "https://feeds.reuters.com/reuters/businessNews",
    },
    {
        "name": "Yahoo Finance",
        "url": "https://finance.yahoo.com/news/rssindex",
    },
    {
        "name": "CNBC Top News",
        "url": "https://www.cnbc.com/id/100003114/device/rss/rss.html",
    },
    {
        "name": "Investing.com",
        "url": "https://www.investing.com/rss/news.rss",
    },
]

FINANCIAL_KEYWORDS = [
    "oil", "stock", "market", "economy", "inflation", "fed", "interest rate",
    "trade", "gdp", "recession", "crypto", "bitcoin", "gold", "bond",
    "opec", "earnings", "ipo", "merger", "acquisition", "sector", "energy",
    "logistics", "transport", "freight", "fuel", "price", "supply", "demand",
]


def _is_financial(text: str) -> bool:
    text_lower = text.lower()
    return any(kw in text_lower for kw in FINANCIAL_KEYWORDS)


def _parse_feed(source: Dict[str, Any]) -> List[Dict[str, Any]]:
    """Synchronous RSS parse for one source."""
    items = []
    try:
        feed = feedparser.parse(source["url"])
        for entry in feed.entries[:10]:  # cap at 10 per feed
            title = entry.get("title", "")
            summary = entry.get("summary", entry.get("description", ""))
            if not _is_financial(title + " " + summary):
                continue
            items.append({
                "id": f"rss_{hash(title) & 0xFFFFFF}",
                "headline": title,
                "content": summary[:500],
                "source": source["name"],
                "url": entry.get("link", ""),
                "timestamp": entry.get("published", datetime.utcnow().isoformat()),
            })
    except Exception as e:
        print(f"[RSSService] Failed to parse {source['name']}: {e}")
    return items


async def fetch_rss_news() -> List[Dict[str, Any]]:
    """Fetch from all RSS sources concurrently, return deduplicated results."""
    loop = asyncio.get_event_loop()
    tasks = [
        loop.run_in_executor(None, _parse_feed, source)
        for source in RSS_SOURCES
    ]
    results = await asyncio.gather(*tasks, return_exceptions=True)

    all_items: List[Dict[str, Any]] = []
    seen_headlines = set()
    for result in results:
        if isinstance(result, list):
            for item in result:
                key = item["headline"][:60].lower()
                if key not in seen_headlines:
                    seen_headlines.add(key)
                    all_items.append(item)

    return all_items
