from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from playwright.async_api import Browser, Playwright, async_playwright
import asyncio

app = FastAPI()

semaphore = asyncio.Semaphore(1)
browser: Browser | None = None
playwright: Playwright | None = None


class FetchRequest(BaseModel):
    url: str


@app.on_event("startup")
async def startup():
    global playwright, browser
    if playwright is None:
        playwright = await async_playwright().start()
    if browser is None:
        browser = await playwright.chromium.launch(
            headless=True,
            args=[
                "--no-sandbox",
                "--disable-setuid-sandbox",
                "--disable-dev-shm-usage",
            ],
        )


@app.on_event("shutdown")
async def shutdown():
    global browser, playwright
    if browser:
        await browser.close()
        browser = None
    if playwright:
        await playwright.stop()
        playwright = None


async def _text(page, *selectors):
    """Try selectors in order, return first match's inner text stripped, or None."""
    for sel in selectors:
        try:
            el = await page.query_selector(sel)
            if el:
                t = await el.inner_text()
                if t and t.strip():
                    return t.strip()
        except Exception:
            pass
    return None


@app.post("/fetch")
async def fetch_url(req: FetchRequest):
    if browser is None:
        raise HTTPException(status_code=503, detail="browser not ready")

    async with semaphore:
        context = await browser.new_context(
            user_agent="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36",
            viewport={"width": 1280, "height": 800},
        )

        page = await context.new_page()
        try:
            await page.goto(req.url, wait_until="load", timeout=60000)
            await asyncio.sleep(2)

            body_text = await page.inner_text("body")

            # Expired check — before anything else
            expired_phrases = [
                "this job is no longer advertised",
                "no longer advertised",
                "this job ad has expired",
                "job ad has been removed",
            ]
            if any(p in body_text.lower() for p in expired_phrases):
                return {
                    "url": req.url,
                    "expired": True,
                    "text": "",
                    "job_title": None,
                    "company": None,
                    "location": None,
                    "salary": None,
                    "quick_apply": False,
                }

            # Structured fields from SEEK data-automation attributes
            job_title = await _text(
                page,
                "[data-automation='job-title']",
                "h1[class*='job-title']",
                "h1",
            )

            company = await _text(
                page,
                "[data-automation='advertiser-name']",
                "[data-automation='job-detail-company']",
                "[class*='advertiser-name']",
            )

            location = await _text(
                page,
                "[data-automation='job-detail-location']",
                "[data-automation='location']",
                "[class*='location']",
            )

            salary = await _text(
                page,
                "[data-automation='job-detail-salary']",
                "[data-automation='salary']",
                "[class*='salary']",
            )

            # Quick Apply: look for a button with that text
            quick_apply = False
            try:
                qa_btn = await page.query_selector(
                    "button:has-text('Quick apply'), "
                    "a:has-text('Quick apply'), "
                    "[data-automation='apply-button']"
                )
                if qa_btn:
                    btn_text = (await qa_btn.inner_text() or "").lower()
                    quick_apply = "quick" in btn_text
            except Exception:
                pass

            # JD text
            content = None
            for selector in [
                "[data-automation='jobAdDetails']",
                "[data-automation='job-detail-page']",
                "article",
                "main",
            ]:
                el = await page.query_selector(selector)
                if el:
                    content = await el.inner_text()
                    break

            if not content:
                content = body_text

            return {
                "url": req.url,
                "expired": False,
                "text": content.strip(),
                "job_title": job_title,
                "company": company,
                "location": location,
                "salary": salary,
                "quick_apply": quick_apply,
            }
        except Exception as e:
            raise HTTPException(status_code=500, detail=str(e))
        finally:
            await page.close()
            await context.close()


@app.get("/health")
async def health():
    return {"status": "ok"}
