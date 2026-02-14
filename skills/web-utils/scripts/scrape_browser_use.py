from browser_use import Agent, Browser, ChatBrowserUse
import asyncio
import sys
import json
import os

# Usage: python3 scrape_browser_use.py <url>


async def main():
    if len(sys.argv) < 2:
        print(json.dumps({"error": "No URL provided"}))
        sys.exit(1)

    url = sys.argv[1]

    try:
        # Defaults to local chromium if not configured for cloud
        browser = Browser()

        # Defaults to OpenAI via .env
        llm = ChatBrowserUse()

        # Task: Go to URL and return content
        task_prompt = f"Navigate to {url}. Extract the page title and the full main text content. Return the result as JSON with keys 'title' and 'text'."

        agent = Agent(
            task=task_prompt,
            llm=llm,
            browser=browser,
        )

        history = await agent.run()
        result = history.final_result()

        # Try to parse JSON result from LLM, or return string
        try:
            # Basic attempt to find JSON blob
            if result:
                json.loads(result)
                print(result)
            else:
                print(json.dumps({"text": result}))
        except Exception:
            print(json.dumps({"text": result}))

    except Exception as e:
        print(json.dumps({"error": str(e)}))
        sys.exit(1)


if __name__ == "__main__":
    asyncio.run(main())
