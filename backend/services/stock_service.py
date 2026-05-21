"""
Stock Service — Real-time & historical price data via yfinance.
No API key required.
"""
import asyncio
from typing import Dict, Any, Optional

import yfinance as yf

# Tickers we care about in the demo scenario
TRACKED_TICKERS = {
    "SP500":   "^GSPC",
    "OIL_WTI": "CL=F",
    "VIX":     "^VIX",
    "AAPL":    "AAPL",
    "XOM":     "XOM",   # Energy (Exxon) proxy for Energy Hedging Fund
    "FDX":     "FDX",   # FedEx proxy for XYZ Logistics
}

# Mock prices used as fallback if yfinance is unavailable
MOCK_PRICES = {
    "SP500":   5234.18,
    "OIL_WTI": 94.50,
    "VIX":     28.40,
    "AAPL":    178.20,
    "XOM":     118.90,
    "FDX":     248.60,
}

MOCK_CHANGES = {
    "SP500":   1.2,
    "OIL_WTI": 18.0,
    "VIX":     -4.3,
    "AAPL":    -0.85,
    "XOM":     2.4,
    "FDX":     -5.6,
}


def _fetch_price_and_change_sync(symbol: str) -> Optional[tuple]:
    try:
        ticker = yf.Ticker(symbol)
        hist = ticker.history(period="2d")
        if not hist.empty:
            curr_price = float(hist["Close"].iloc[-1])
            if len(hist) >= 2:
                prev_price = float(hist["Close"].iloc[-2])
            else:
                prev_price = float(hist["Open"].iloc[-1])
            pct_change = ((curr_price - prev_price) / prev_price) * 100
            return curr_price, pct_change
    except Exception as e:
        print(f"[StockService] yfinance error for {symbol}: {e}")
    return None


async def get_market_prices() -> Dict[str, float]:
    """Fetch current prices and changes for all tracked tickers."""
    loop = asyncio.get_event_loop()
    prices: Dict[str, float] = {}

    tasks = {
        name: loop.run_in_executor(None, _fetch_price_and_change_sync, ticker)
        for name, ticker in TRACKED_TICKERS.items()
    }

    for name, task in tasks.items():
        try:
            result = await task
            if result is not None:
                prices[name] = result[0]
                prices[f"{name}_change"] = result[1]
            else:
                prices[name] = MOCK_PRICES[name]
                prices[f"{name}_change"] = MOCK_CHANGES[name]
        except Exception:
            prices[name] = MOCK_PRICES[name]
            prices[f"{name}_change"] = MOCK_CHANGES[name]

    print(f"[StockService] Fetched prices: {prices}")
    return prices


async def get_price(name: str) -> float:
    """Fetch a single ticker price by friendly name."""
    symbol = TRACKED_TICKERS.get(name)
    if not symbol:
        return MOCK_PRICES.get(name, 0.0)

    loop = asyncio.get_event_loop()
    try:
        result = await loop.run_in_executor(None, _fetch_price_and_change_sync, symbol)
        return result[0] if result is not None else MOCK_PRICES.get(name, 0.0)
    except Exception:
        return MOCK_PRICES.get(name, 0.0)
