"""
Gemini Service — Wrapper around Google Generative AI (Gemini).
Falls back to structured mock responses if no API key is set.
"""
import json
import re
from typing import Any, Dict

# --- GEMINI BACKUP ---
# import google.generativeai as genai
# from config import GEMINI_API_KEY, USE_REAL_LLM, GEMINI_MODEL
# if USE_REAL_LLM:
#     genai.configure(api_key=GEMINI_API_KEY)
#     _model = genai.GenerativeModel(GEMINI_MODEL)
# else:
#     _model = None
# ---------------------

from config import GROQ_API_KEY, USE_REAL_LLM
from groq import Groq

if USE_REAL_LLM:
    client = Groq(api_key=GROQ_API_KEY)
else:
    client = None


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def _extract_json(text: str) -> Dict[str, Any]:
    """Extract the first JSON object found in an LLM response string."""
    match = re.search(r"\{[\s\S]*?\}", text)
    if match:
        try:
            return json.loads(match.group())
        except json.JSONDecodeError:
            pass
    return {}


# ---------------------------------------------------------------------------
# Public API
# ---------------------------------------------------------------------------

async def analyze_news_intelligence(news_items: list, social_signals: list) -> Dict[str, Any]:
    """
    Given raw news + social data, return structured sector intelligence.
    Output keys: affected_negative, affected_positive, key_event, confidence
    """
    mock_response = {
        "key_event": "OPEC announces unexpected oil production cuts",
        "affected_negative": ["transportation", "logistics", "airlines"],
        "affected_positive": ["energy", "oil_etfs", "renewables"],
        "confidence": 0.91,
        "reasoning": "Rising oil prices directly compress transportation margins while benefiting upstream energy producers.",
    }

    if not USE_REAL_LLM or not news_items:
        return mock_response

    headlines = "\n".join(
        f"- {item.get('headline', '')}" for item in news_items[:10]
    )
    social_posts = "\n".join(
        f"- [{s.get('platform', 'X')}] {s.get('post', '')}" for s in social_signals[:5]
    )

    prompt = f"""You are a financial intelligence analyst.

Analyze these financial news headlines and social signals:

NEWS HEADLINES:
{headlines}

SOCIAL SIGNALS:
{social_posts}

Return a JSON object with these exact keys:
- key_event: string (most impactful event in one sentence)
- affected_negative: list of strings (sectors negatively impacted)
- affected_positive: list of strings (sectors positively impacted)
- confidence: float 0-1
- reasoning: string (1-2 sentence explanation)

Return ONLY the JSON object, no other text."""

    try:
        # --- GEMINI BACKUP ---
        # response = _model.generate_content(prompt)
        # result = _extract_json(response.text)
        # ---------------------
        completion = client.chat.completions.create(
            model="llama-3.1-8b-instant",
            messages=[{"role": "user", "content": prompt}]
        )
        result = _extract_json(completion.choices[0].message.content)
        
        if result:
            return result
    except Exception as e:
        print(f"[GeminiService/Groq] analyze_news_intelligence error: {e}")

    return mock_response


async def generate_insight(
    sentiment: Dict[str, Any],
    news_intelligence: Dict[str, Any],
    market_prices: Dict[str, Any],
) -> Dict[str, Any]:
    """
    Synthesize a core market insight from sentiment + news intelligence.
    Output keys: summary, severity, sector_focus, confidence
    """
    mock_response = {
        "summary": "Rising oil prices combined with deeply negative transportation sentiment will significantly compress logistics profitability, creating a high-severity portfolio risk.",
        "severity": "HIGH",
        "sector_focus": "transportation",
        "confidence": 0.91,
        "tags": ["crude_oil", "opec", "logistics_beta", "fuel_cost", "supply_hedge"],
    }

    if not USE_REAL_LLM:
        return mock_response

    prompt = f"""You are an autonomous financial insight engine.

Given this market intelligence, generate a single core actionable insight:

NEWS INTELLIGENCE:
- Key event: {news_intelligence.get('key_event')}
- Negatively affected sectors: {news_intelligence.get('affected_negative')}
- Positively affected sectors: {news_intelligence.get('affected_positive')}

SENTIMENT:
- Overall score: {sentiment.get('score')} ({sentiment.get('label')})
- Most negative sector: {sentiment.get('most_negative_sector')}

MARKET PRICES:
- Oil/WTI: {market_prices.get('OIL_WTI')}
- VIX: {market_prices.get('VIX')}
- S&P 500: {market_prices.get('SP500')}

Return a JSON object with these exact keys:
- summary: string (2-3 sentence insight statement)
- severity: string (one of: LOW, MEDIUM, HIGH, CRITICAL)
- sector_focus: string (primary sector most affected)
- confidence: float 0-1
- tags: list of strings (5 financial keyword tags)

Return ONLY the JSON object, no other text."""

    try:
        # --- GEMINI BACKUP ---
        # response = _model.generate_content(prompt)
        # result = _extract_json(response.text)
        # ---------------------
        completion = client.chat.completions.create(
            model="llama-3.1-8b-instant",
            messages=[{"role": "user", "content": prompt}]
        )
        result = _extract_json(completion.choices[0].message.content)

        if result:
            return result
    except Exception as e:
        err_msg = str(e)
        if "429" in err_msg or "Rate limit" in err_msg or "Quota exceeded" in err_msg:
            print(f"[GeminiService/Groq] generate_insight: API Rate Limit Hit. Auto-triggering mock fallback.")
        else:
            print(f"[GeminiService/Groq] generate_insight error: {e}")
        return mock_response


async def generate_decision(
    risk_assessment: Dict[str, Any],
    insight: Dict[str, Any],
    portfolio: Dict[str, Any],
) -> Dict[str, Any]:
    """
    Generate autonomous trade decisions based on risk + insight.
    Output keys: actions, reasoning, confidence
    """
    mock_response = {
        "actions": [
            {"type": "SELL", "asset": "FDX", "target_pct": 15.0, "reason": "High exposure to fuel cost increases"},
            {"type": "BUY",  "asset": "XOM", "target_pct": 40.0, "reason": "Direct hedge against rising oil prices"},
        ],
        "reasoning": "Portfolio has 35% exposure to FDX which is severely impacted by fuel costs. Reducing to 15% and rotating into XOM (20% → 40%) creates a direct macro hedge.",
        "confidence": 0.88,
        "risk_delta": "HIGH → MEDIUM",
    }

    if not USE_REAL_LLM:
        return mock_response

    holdings = json.dumps(portfolio.get("holdings", {}), indent=2)

    prompt = f"""You are an autonomous portfolio decision agent.

CURRENT PORTFOLIO:
{holdings}

RISK ASSESSMENT:
- Risk Level: {risk_assessment.get('risk_level')}
- Risk Score: {risk_assessment.get('risk_score')}
- Most exposed asset: {risk_assessment.get('most_exposed_asset')}
- Expected loss if unmitigated: ${risk_assessment.get('expected_loss')}

MARKET INSIGHT:
- {insight.get('summary')}
- Severity: {insight.get('severity')}
- Negative sectors: {insight.get('affected_negative_sectors')}
- Positive sectors: {insight.get('affected_positive_sectors')}

Generate autonomous trade decisions to mitigate risk.
Return a JSON object with these exact keys:
- actions: list of objects, each with: type (BUY/SELL), asset, target_pct (target allocation), reason
- reasoning: string (2-3 sentence explanation of the strategy)
- confidence: float 0-1
- risk_delta: string (e.g. "HIGH → MEDIUM")

Return ONLY the JSON object, no other text."""

    try:
        # --- GEMINI BACKUP ---
        # response = _model.generate_content(prompt)
        # result = _extract_json(response.text)
        # ---------------------
        completion = client.chat.completions.create(
            model="llama-3.1-8b-instant",
            messages=[{"role": "user", "content": prompt}]
        )
        result = _extract_json(completion.choices[0].message.content)

        if result:
            return result
    except Exception as e:
        print(f"[GeminiService/Groq] generate_decision error: {e}")

    return mock_response
