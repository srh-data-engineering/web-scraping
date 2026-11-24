# Web Scraping Lab

**Data Engineering 1 · SRH Hochschule Heidelberg**  
Prof. Dr.-Ing. Binh Vu

---

## Contents

| File | Description |
|---|---|
| `Web_Scraping.pdf` | Lecture slides — Web data: from web services to web scraping |
| `Web_Scraping.html` | Interactive study guide with diagrams, tool comparisons, and the full hands-on lab |
| `web_scraping_setup.sh` | One-shot setup script — installs everything and writes all lab files |

---

## Getting Started (3 commands)

```bash
# 1. Clone this repository
git clone <REPO_URL>
cd web-scraping

# 2. Run the setup script
bash web_scraping_setup.sh

# 3. Activate the environment and run the lab
source ~/web-scraping-lab/venv/bin/activate
python3 ~/web-scraping-lab/web_scraping_lab.py
```

> **Requirement:** Ubuntu 22.04 (or any Debian-based Linux).  
> The script handles Python, the virtual environment, all libraries, Playwright Chromium, and writes every lab file automatically.

---

## What the Setup Script Does

1. Installs `python3`, `pip`, `venv` via `apt`
2. Creates `~/web-scraping-lab/` with a Python virtual environment
3. Installs: `requests`, `beautifulsoup4`, `playwright`, `pandas`, `scrapy`, `lxml`
4. Downloads and installs the Playwright Chromium browser
5. Writes all 7 lab Python files into `~/web-scraping-lab/`
6. Runs `check_setup.py` to verify everything before you start

---

## Lab Structure

| Phase | Task | Slide Reference |
|---|---|---|
| 0 | robots.txt + ethical checklist | Slides 26–29 |
| 1 | DOM inspection in browser DevTools | Slides 10–12 |
| 2 | Static scraping with BeautifulSoup | Slides 13–14 |
| 3 | Prove static scraper fails on JS page | Slides 18–19 |
| 4 | Dynamic scraping with Playwright | Slides 22–23 |
| 5 | Multi-page pagination | Key Concepts |
| **6** | **Save to CSV — assignment deliverable** | **Slide 30** |
| 7 | Extension challenges (optional) | Slides 15–16 |

Open `Web_Scraping.html` in your browser for the full interactive guide.

---

## Running Individual Phases

```bash
cd ~/web-scraping-lab
source venv/bin/activate

bash lab.sh check_robots.py      # Phase 0
bash lab.sh phase2_static.py     # Phase 2
bash lab.sh phase3_broken.py     # Phase 3
bash lab.sh phase4_dynamic.py    # Phase 4
bash lab.sh phase5_paginated.py  # Phase 5
bash lab.sh web_scraping_lab.py  # Phase 6 — full solution + CSV output
```
