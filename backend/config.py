import os
import pathlib
from dotenv import load_dotenv

BASE_DIR   = pathlib.Path(__file__).parent
load_dotenv(BASE_DIR / ".env")

# --- API Keys ---
GEMINI_API_KEY: str = os.getenv("GEMINI_API_KEY", "")
GROQ_API_KEY: str   = os.getenv("GROQ_API_KEY", "")
NEWSAPI_KEY: str    = os.getenv("NEWSAPI_KEY", "")
GNEWS_API_KEY: str  = os.getenv("GNEWS_API_KEY", "")
GEMINI_MODEL: str   = os.getenv("GEMINI_MODEL", "gemini-1.5-flash")

# --- Feature Flags ---
USE_REAL_NEWS: bool  = bool(NEWSAPI_KEY)
USE_REAL_LLM: bool   = bool(GROQ_API_KEY)
USE_REAL_STOCK: bool = True   # yfinance — always on, no key needed

# --- Paths ---
DATA_DIR   = BASE_DIR / "data"
MOCK_NEWS  = DATA_DIR / "mock_news_feed.json"
MOCK_SOCIAL = DATA_DIR / "mock_social.json"
PORTFOLIO_DEFAULT = DATA_DIR / "portfolio_default.json"

