# OptionXI – Open Source Virtual Trading App

**OptionXI** is India’s first open-source virtual trading app for learning, strategy testing, and community collaboration.


[![Play Store](https://upload.wikimedia.org/wikipedia/commons/7/78/Google_Play_Store_badge_EN.svg)](https://play.google.com/store/apps/details?id=com.optionxi.app)
![TruffleHog Scan](https://github.com/optionxi/optionxi-flutter-community/actions/workflows/trufflehog.yml/badge.svg)
[![Gitleaks Scan](https://github.com/optionxi/optionxi-flutter-community/actions/workflows/gitleaks.yml/badge.svg)](https://github.com/optionxi/optionxi-flutter-community/actions/workflows/gitleaks.yml)
![Build Scan](https://github.com/optionxi/optionxi-flutter-community/actions/workflows/flutter-build.yml/badge.svg)
![CodeRabbit Pull Request Reviews](https://img.shields.io/coderabbit/prs/github/optionxi/optionxi-flutter-community?utm_source=oss&utm_medium=github&utm_campaign=optionxi%2Foptionxi-flutter-community&labelColor=171717&color=FF570A&link=https%3A%2F%2Fcoderabbit.ai&label=CodeRabbit+Reviews)

---


<a href="https://www.producthunt.com/products/optionxi?embed=true&utm_source=badge-featured&utm_medium=badge&utm_source=badge-optionxi&#0045;open&#0045;source&#0045;trading&#0045;app" target="_blank">
  <img src="https://api.producthunt.com/widgets/embed-image/v1/featured.svg?post_id=1016349&theme=light&t=1758272315158" alt="OptionXI&#0032;&#0045;&#0032;Open&#0032;Source&#0032;Trading&#0032;App | Product Hunt" width="250" height="54" />
</a>  

📱 Available now on [Google Play Store →](https://play.google.com/store/apps/details?id=com.optionxi.app)

> ⚠️ This repository contains the **open-source Flutter front end**.
> The backend (Supabase/Postgres) will be released as open-source soon.

---

## 🌟 App Preview

![App Feature Image](screenshots/Featue%20Image.png)

---


## 🚀 What is OptionXI?

**OptionXI** is a powerful, easy-to-use app for simulating stock market trading using real market data from the Indian stock market. Whether you're a beginner or a seasoned trader, you can practice, learn, and even contribute to a system built with transparency and accountability in mind.

---

### 📸 Screenshots

Here are some screenshots showcasing various parts of the app:

<p>
  <img src="screenshots/Home%20Page%20New.png" width="120"/>
  <img src="screenshots/Home%20Page%20new%202.png" width="120"/>
  <img src="screenshots/One%20click%20Login.png" width="120"/>
  <img src="screenshots/Interactive%20Profile.png" width="120"/>
  <img src="screenshots/Search%20Stocks.png" width="120"/>
  <img src="screenshots/Market%20Sentiment.png" width="120"/>
  <img src="screenshots/Market%20Tools.png" width="120"/>
</p>

Made using [The Applaunchpad](https://theapplaunchpad.com/) - Create your own stunning playstore/appstore screenshots

---

## 🔑 Key Features

- ✅ **Virtual Trading**
  - Simulate trades in NIFTY 50, BankNIFTY, and Options
  - Based on real or previous day data
  - Practice paper trading and backtest strategies

- 📊 **Stock Screeners**
  - Scan by performance, volume, and price action
  - Discover trade opportunities easily

- 🛎️ **Alerts & Watchlists**
  - Create custom watchlists
  - Get real-time alerts on price moves

- 📈 **Charts & Insights**
  - Get detailed stock data, charts, option chain
  - Analyze previous day data for educational purposes

- 🧠 **Educational Focus**
  - No real money involved
  - Ideal for students, traders, and fintech learners

- 🤖 **Coming Soon: Algorithmic Trading**
  - Real-time strategy-based order placement
  - Backtesting and automation framework

---
## 🔓 Why Open Source?

India is flooded with trading "gurus" — some are genuine, using **technical analysis**, **breakout strategies**, and legal methods to share real insights. We support and appreciate these educators.

But many others rely on **hype**, throwing around terms like "AI" and "algo-based tips" to sell overpriced courses with little actual value. Even SEBI-registered entities often lack **transparency**, **consistency**, and **accountability**.

**OptionXI is our alternative:**

* A **centralized**, **transparent**, **open-source** platform
* Public trade recommendations with **auditable** track records
* Community-reviewed accuracy metrics
* Contribute new trade ideas, and the system will **auto-analyze** them
* Backed by community, not hidden behind paywalls

⚠️ **Important:** This is for **educational use only**. Real-money trading will only be available via broker integrations in the future.

---

## 🌐 Tech Stack

- 💙 Flutter for Android/iOS
- 🔐 Firebase Auth + Notifications
- 🧠 Supabase (Postgres) backend (coming soon)
- 📦 Clean MVVM + Controller architecture
- ☁️ Web app: [app.optionxi.com](https://app.optionxi.com) *(open-sourcing soon)*

---

## 📥 Installation (Dev Setup)

```bash
git clone https://github.com/optionxi/optionxi-flutter-community.git
cd optionxi-flutter-community
flutter pub get
flutter run
```

You'll need:

* Flutter 3.19+
* Firebase project (optional for dev)
* Supabase keys (can use `.env`)

Added gitleaks check
```
git config core.hooksPath .githooks
```
Increasing the buffer
```
git config http.postBuffer 524288000
```

---

## 🤝 Contributions Welcome!

We're building India's first open, free, educational trading platform.
Feel free to:

* Fork the repo
* Add new features
* Report bugs
* Suggest educational tools
* Improve UI/UX

📢 Planning to support new modules like:

* Public trade audit logs
* Accuracy leaderboard
* Trade strategy visualizer
* Broker integrations (via Fyers, Zerodha APIs)

---

## 🙌 Support & Funding

We are building this platform for **open learning and transparency**, not for profit.
If you want to support the mission:

* Contribute code
* Spread the word
* Sponsor us on GitHub (coming soon)
* Reach out to collaborate

---

## 📱 Connect With Us

* 📷 Instagram: [@hi\_functioning\_sociopath](https://instagram.com/hi_functioning_sociopath)
* 🧑‍💻 GitHub: [@katmakhan](https://github.com/katmakhan)

---

## 📜 License

MIT License — Free to use, modify, and build upon.

---

### 💬 Final Word

> "We don't need another expensive course. We need tools to help us **think, test, and learn** trading in the open."

Help us build that tool. 🛠️
Let's make stock education free, accessible, and community-driven.

---
## 🤖 AI Assistance Credits

Most of the UI and code in this project was generated with the help of AI. It's efficient, reliable, and good enough to put into production. In fact, around **90% of the code was developed by AI**, showing how powerful and practical AI tools have become in modern development workflows.

## 🤖 AI Platforms Used

<div>

| <img src="https://upload.wikimedia.org/wikipedia/commons/e/ef/ChatGPT-Logo.svg" alt="ChatGPT" width="48" height="48"/> | <img src="https://upload.wikimedia.org/wikipedia/commons/thumb/8/8a/Claude_AI_logo.svg/1380px-Claude_AI_logo.svg.png" alt="Claude" width="148" height="48"/> | <img src="https://upload.wikimedia.org/wikipedia/commons/e/ec/DeepSeek_logo.svg" alt="DeepSeek" width="148" height="48"/> | <img src="https://upload.wikimedia.org/wikipedia/commons/8/8f/Google-gemini-icon.svg" alt="Gemini" width="48" height="48"/> |
|:---:|:---:|:---:|:---:|
| **ChatGPT** | **Claude** | **DeepSeek** | **Gemini** |
| Content Generation | UI Design & Coding | Error Correction | Debugging |

</div>

---

### Platform Details

- **ChatGPT**: I use ChatGPT to help write, brainstorm, and generate high-quality content. – [chat.openai.com](https://chat.openai.com)
- **Claude**: My go-to for designing clean interfaces and writing structured code. – [claude.ai](https://claude.ai)
- **DeepSeek**: I rely on DeepSeek to catch and fix tricky bugs in my code. – [deepseek.com](https://deepseek.com)
- **Gemini**: Great for deep debugging and understanding complex code behavior. – [gemini.google.com](https://gemini.google.com)

---

<div align="center">

*Building the future of open-source trading education with human creativity and AI efficiency* ✨

</div>
