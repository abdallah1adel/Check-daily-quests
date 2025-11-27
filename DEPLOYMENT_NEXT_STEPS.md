# 🚀 Deployment Guide (Dashboard Method)

Since the CLI is causing issues, we will do everything via the **Railway Website**. This is easier and more reliable.

## 1. Configure Server on Railway

1.  Open your [Railway Dashboard](https://railway.app/dashboard).
2.  Click on your project.
3.  Click on the **Service** card (the box with your code name).
4.  Click on the **Settings** tab.
5.  Scroll down to the **Build & Deploy** section.
6.  Find the **Start Command** field.
7.  **Paste this EXACT command:**
    ```bash
    npx prisma migrate deploy && node create-promo.js && node dist/index.js
    ```
    *(This automatically sets up your database and promo codes every time the server starts.)*

8.  Click **Redeploy** (or wait for it to auto-deploy).

## 2. Get Your Backend URL

1.  Still in the Railway Dashboard, go to the **Networking** tab.
2.  Under "Public Networking", you should see a URL (e.g., `https://pcpos-production.up.railway.app`).
3.  **Copy this URL.**
4.  **IMPORTANT:** You must add `/api` to the end of it.
    *   Final URL format: `https://your-project.up.railway.app/api`

## 3. Connect Xcode (The "Xcode Steps")

Now we tell your iPhone app where the server is.

1.  Open **Xcode**.
2.  Look at the **Top Menu Bar** (very top of screen).
3.  Click **Product** → **Scheme** → **Edit Scheme...**
4.  A window will pop up:
    *   **Left Sidebar:** Click **Run** (Play icon).
    *   **Center Tabs:** Click **Arguments**.
    *   **Bottom Section:** Find **Environment Variables**.
5.  Click the **+** (Plus) button.
6.  **Name:** `BACKEND_URL`
7.  **Value:** Paste your URL ending in `/api` (e.g., `https://...app/api`).
8.  Click **Close**.

## 4. Verify It Works

1.  Run the app in the Simulator or on your Phone.
2.  Go to **Settings** → **Rewards**.
3.  If you see a referral code (or it generates one), **YOU ARE DONE!** �
