from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from playwright.async_api import async_playwright
import asyncio

app = FastAPI()


class FetchRequest(BaseModel):
    url: str


@app.post("/fetch")
async def fetch_url(req: FetchRequest):
    try:
        async with async_playwright() as p:
            browser = await p.chromium.launch(
                headless=True,
                args=[
                    "--no-sandbox",
                    "--disable-setuid-sandbox",
                    "--disable-dev-shm-usage",
                ],
            )
            context = await browser.new_context(
                user_agent="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36",
                viewport={"width": 1280, "height": 800},
            )
            page = await context.new_page()
            await page.goto(req.url, wait_until="load", timeout=60000)
            await asyncio.sleep(2)
            title = await page.title()

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
                content = await page.inner_text("body")

            await browser.close()
            return {"title": title, "text": content.strip(), "url": req.url}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@app.get("/health")
async def health():
    return {"status": "ok"}
