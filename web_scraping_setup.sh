#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
# SRH Hochschule Heidelberg — Data Engineering 1
# Web Scraping Lab — One-shot setup for Ubuntu 22.04
#
# Usage (after git clone):
#   git clone <REPO_URL> && cd web-scraping
#   bash web_scraping_setup.sh
#   source ~/web-scraping-lab/venv/bin/activate
# ─────────────────────────────────────────────────────────────
set -e

G='\033[0;32m'; O='\033[0;33m'; R='\033[0;31m'; B='\033[1;34m'; N='\033[0m'
LAB="$HOME/web-scraping-lab"

banner() { echo -e "\n${B}▸ $1${N}"; }
ok()     { echo -e "${G}  ✓ $1${N}"; }
warn()   { echo -e "${O}  ! $1${N}"; }

echo -e "${O}"
echo "  ╔══════════════════════════════════════════╗"
echo "  ║  SRH — Web Scraping Lab  Setup Script   ║"
echo "  ╚══════════════════════════════════════════╝"
echo -e "${N}"

# ── 1. System packages ────────────────────────────────────────
banner "Installing system packages (requires sudo)"
sudo apt-get update -qq
sudo apt-get install -y -qq python3 python3-pip python3-venv curl
ok "System packages ready"

# ── 2. Project folder ─────────────────────────────────────────
banner "Creating project folder: $LAB"
mkdir -p "$LAB"
cd "$LAB"
ok "Folder: $LAB"

# ── 3. Virtual environment ────────────────────────────────────
banner "Creating Python virtual environment"
python3 -m venv venv
source venv/bin/activate
pip install -q --upgrade pip
ok "venv created and activated"

# ── 4. Python libraries ───────────────────────────────────────
banner "Installing Python libraries"
pip install -q requests beautifulsoup4 playwright pandas scrapy lxml
ok "requests, beautifulsoup4, playwright, pandas, scrapy, lxml installed"

# ── 5. Playwright browser ─────────────────────────────────────
banner "Installing Playwright Chromium browser"
playwright install chromium
ok "Playwright Chromium binary downloaded"

banner "Installing Playwright system-level dependencies (requires sudo)"
# Use the venv's full binary path so sudo can find it regardless of PATH
sudo "$LAB/venv/bin/playwright" install-deps chromium 2>/dev/null || \
  warn "playwright install-deps skipped — if check_setup.py reports a Chromium error, run:\n  source ~/web-scraping-lab/venv/bin/activate\n  sudo \$(which playwright) install-deps chromium"
ok "System dependency step complete"

# ── 6. Write lab files ────────────────────────────────────────
banner "Writing lab Python files"

# check_setup.py ───────────────────────────────────────────────
cat > check_setup.py << 'PYEOF'
import sys
print(f"Python: {sys.version}\n")
missing = []
for lib in ["requests", "bs4", "playwright", "pandas", "scrapy"]:
    try:
        __import__(lib)
        print(f"  {lib:<18} OK")
    except ImportError:
        print(f"  {lib:<18} MISSING")
        missing.append(lib)

try:
    from playwright.sync_api import sync_playwright
    with sync_playwright() as p:
        b = p.chromium.launch(headless=True)
        b.close()
    print(f"  {'Playwright Chromium':<18} OK")
except Exception as e:
    print(f"  {'Playwright Chromium':<18} FAILED")
    print(f"  → {e}")
    print("  → Fix: sudo $(which playwright) install-deps chromium")
    missing.append("Playwright Chromium")

if missing:
    print(f"\n[!] Issues with: {', '.join(missing)}")
    print("    Python libs:      pip install requests beautifulsoup4 playwright pandas scrapy lxml")
    print("    Playwright deps:  sudo $(which playwright) install-deps chromium")
else:
    print("\nAll checks passed — ready for the lab!")
PYEOF

# check_robots.py ──────────────────────────────────────────────
cat > check_robots.py << 'PYEOF'
import requests
target = "http://quotes.toscrape.com"
r = requests.get(f"{target}/robots.txt")
print(f"Status : {r.status_code}")
if r.status_code == 404:
    print("(no robots.txt — site imposes no crawl restrictions)")
elif r.text.strip():
    print(r.text)
else:
    print("(empty robots.txt — no crawl restrictions)")
PYEOF

# phase2_static.py ─────────────────────────────────────────────
cat > phase2_static.py << 'PYEOF'
import requests, time
from bs4 import BeautifulSoup

BASE_URL   = "http://quotes.toscrape.com"
all_quotes = []
page_url   = BASE_URL

while page_url:
    resp = requests.get(page_url, headers={"User-Agent": "SRH-Lab-Bot/1.0"})
    if resp.status_code != 200:
        print(f"Error {resp.status_code}"); break

    soup = BeautifulSoup(resp.text, "html.parser")
    for block in soup.find_all("div", class_="quote"):
        text   = block.find("span",  class_="text").get_text(strip=True)
        author = block.find("small", class_="author").get_text(strip=True)
        tags   = [t.get_text(strip=True) for t in block.find_all("a", class_="tag")]
        all_quotes.append({"quote": text, "author": author, "tags": ", ".join(tags)})

    nxt      = soup.find("li", class_="next")
    page_url = BASE_URL + nxt.find("a")["href"] if nxt else None
    time.sleep(1)

print(f"Collected {len(all_quotes)} quotes")  # expected: 100
print(all_quotes[0])
PYEOF

# phase3_broken.py ─────────────────────────────────────────────
cat > phase3_broken.py << 'PYEOF'
import requests
from bs4 import BeautifulSoup

response = requests.get("http://quotes.toscrape.com/js/")
soup     = BeautifulSoup(response.text, "html.parser")
quotes   = soup.find_all("div", class_="quote")
print(f"Quotes found: {len(quotes)}")   # expected: 0  — proves JS problem

print("\n--- Quotes container (JavaScript fills this after page load) ---")
print(soup.find(id="quotes"))  # prints <div id="quotes"></div> — empty until JS runs
PYEOF

# phase4_dynamic.py ────────────────────────────────────────────
cat > phase4_dynamic.py << 'PYEOF'
from playwright.sync_api import sync_playwright

all_quotes = []
with sync_playwright() as p:
    browser = p.chromium.launch(headless=True)
    page    = browser.new_page()
    page.goto("http://quotes.toscrape.com/js/")
    page.wait_for_selector("div.quote")          # auto-wait for JS render

    for block in page.query_selector_all("div.quote"):
        text   = block.query_selector("span.text").inner_text()
        author = block.query_selector("small.author").inner_text()
        tags   = [t.inner_text() for t in block.query_selector_all("a.tag")]
        all_quotes.append({"quote": text, "author": author, "tags": ", ".join(tags)})

    browser.close()

print(f"Quotes found: {len(all_quotes)}")  # expected: 10 (first page)
print(all_quotes[0])
PYEOF

# phase5_paginated.py ──────────────────────────────────────────
cat > phase5_paginated.py << 'PYEOF'
from playwright.sync_api import sync_playwright
import time

all_quotes = []
with sync_playwright() as p:
    browser  = p.chromium.launch(headless=True)
    page     = browser.new_page()
    page.goto("http://quotes.toscrape.com/js/")
    page.wait_for_selector("div.quote")
    page_num = 1

    while True:
        print(f"Scraping page {page_num}...")
        for block in page.query_selector_all("div.quote"):
            all_quotes.append({
                "page":   page_num,
                "quote":  block.query_selector("span.text").inner_text(),
                "author": block.query_selector("small.author").inner_text(),
                "tags":   ", ".join(t.inner_text() for t in block.query_selector_all("a.tag"))
            })
        nxt = page.query_selector("li.next > a")
        if not nxt:
            print("No more pages."); break
        nxt.click()
        page.wait_for_selector("div.quote")
        time.sleep(1)
        page_num += 1

    browser.close()

print(f"\nTotal quotes: {len(all_quotes)}")  # expected: 100
PYEOF

# web_scraping_lab.py (complete solution — Slide 30) ───────────
cat > web_scraping_lab.py << 'PYEOF'
"""
SRH Data Engineering 1 — Web Scraping Lab
Assignment (Slide 30): Scrape a dynamic website → save as CSV
"""
from playwright.sync_api import sync_playwright
import csv, time, requests

# Phase 0: legal pre-flight
robots = requests.get("http://quotes.toscrape.com/robots.txt")
if robots.status_code == 404:
    print("robots.txt: not found (404) — no crawl restrictions\n")
else:
    print("robots.txt:", robots.text.strip() or "(empty — no restrictions)", "\n")

# Phase 5: dynamic scraping with Playwright
all_quotes = []
with sync_playwright() as p:
    browser = p.chromium.launch(headless=True)
    page    = browser.new_page()
    page.goto("http://quotes.toscrape.com/js/")
    page.wait_for_selector("div.quote")
    page_num = 1

    while True:
        for block in page.query_selector_all("div.quote"):
            all_quotes.append({
                "page":   page_num,
                "quote":  block.query_selector("span.text").inner_text(),
                "author": block.query_selector("small.author").inner_text(),
                "tags":   ", ".join(t.inner_text() for t in block.query_selector_all("a.tag"))
            })
        nxt = page.query_selector("li.next > a")
        if not nxt:
            break
        nxt.click()
        page.wait_for_selector("div.quote")
        time.sleep(1)
        page_num += 1

    browser.close()

# Phase 6: save to CSV
with open("quotes_dynamic.csv", "w", newline="", encoding="utf-8") as f:
    writer = csv.DictWriter(f, fieldnames=["page", "quote", "author", "tags"])
    writer.writeheader()
    writer.writerows(all_quotes)

print(f"Done — {len(all_quotes)} rows saved to quotes_dynamic.csv")
PYEOF

ok "Lab files written (7 files)"

# ── 7. Verify installation ────────────────────────────────────
banner "Verifying installation"
python3 check_setup.py

# ── 8. Write activate helper ──────────────────────────────────
cat > "$LAB/lab.sh" << SHEOF
#!/usr/bin/env bash
# Run any lab script with the venv automatically active
# Usage: bash lab.sh <script.py>
source "$LAB/venv/bin/activate"
python3 "\$1"
SHEOF
chmod +x "$LAB/lab.sh"
ok "Helper script created: lab.sh"

# ── Done ──────────────────────────────────────────────────────
echo ""
echo -e "${G}╔══════════════════════════════════════════════════╗${N}"
echo -e "${G}║  Setup complete!                                 ║${N}"
echo -e "${G}╠══════════════════════════════════════════════════╣${N}"
echo -e "${G}║  Activate env (once per terminal):               ║${N}"
echo -e "${G}║    source ~/web-scraping-lab/venv/bin/activate   ║${N}"
echo -e "${G}║                                                   ║${N}"
echo -e "${G}║  Run the full lab (Slide 30 deliverable):        ║${N}"
echo -e "${G}║    python3 ~/web-scraping-lab/web_scraping_lab.py║${N}"
echo -e "${G}╠══════════════════════════════════════════════════╣${N}"
echo -e "${G}║  Run any individual phase:                       ║${N}"
echo -e "${G}║    cd ~/web-scraping-lab                         ║${N}"
echo -e "${G}║    bash lab.sh phase2_static.py                  ║${N}"
echo -e "${G}║    bash lab.sh phase3_broken.py                  ║${N}"
echo -e "${G}║    bash lab.sh phase4_dynamic.py                 ║${N}"
echo -e "${G}║    bash lab.sh phase5_paginated.py               ║${N}"
echo -e "${G}╚══════════════════════════════════════════════════╝${N}"
echo ""
