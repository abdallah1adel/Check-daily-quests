# Backend Deployment Guide - Railway.app

## Why Railway?
- **Free tier**: Perfect for development/testing
- **Automatic deployments**: Push to GitHub → Auto deploy
- **PostgreSQL included**: Database setup in one click
- **Easy environment variables**: Configure in dashboard

---

## Step 1: Sign Up for Railway

1. Go to [railway.app](https://railway.app)
2. Click "Start a New Project"
3. Sign in with GitHub

---

## Step 2: Deploy Backend

### Option A: From GitHub (Recommended)

1. **Push your backend code to GitHub:**
   ```bash
   cd /Users/pcpos/Desktop/MegamanCompanion
   git add backend/
   git commit -m "Add referral system backend"
   git push
   ```

2. **In Railway Dashboard:**
   - Click "New Project"
   - Select "Deploy from GitHub repo"
   - Choose your repository
   - Railway auto-detects Node.js
   - Set root directory: `backend`
   - Click "Deploy"

### Option B: Railway CLI (Quick)

```bash
# Install Railway CLI
npm install -g @railway/cli

# Login
railway login

# Navigate to backend
cd /Users/pcpos/Desktop/MegamanCompanion/backend

# Initialize and deploy
railway init
railway up
```

---

## Step 3: Add PostgreSQL Database

1. In your Railway project
2. Click "+ New"
3. Select "Database"
4. Choose "PostgreSQL"
5. Railway automatically creates `DATABASE_URL` environment variable

---

## Step 4: Set Environment Variables

In Railway dashboard → Variables tab:

```env
DATABASE_URL=postgresql://xxx  # Auto-set by Railway
PORT=3000
NODE_ENV=production
```

---

## Step 5: Run Database Migration

In Railway project → Settings → Terminal:

```bash
npx prisma migrate deploy
npx prisma generate
node create-promo.js
```

Or use Railway CLI locally:
```bash
railway run npx prisma migrate deploy
railway run node create-promo.js
```

---

## Step 6: Get Your Backend URL

Your backend URL will be:
```
https://your-app-name.up.railway.app
```

Copy this URL! You'll need it for iOS.

---

## Step 7: Test Backend

```bash
# Health check
curl https://your-app-name.up.railway.app/health

# Should return:
{"status":"ok","timestamp":"2025-11-26T..."}
```

---

## Step 8: Update iOS App

### Option 1: Environment Variable (Xcode)

1. Open Xcode
2. Product → Scheme → Edit Scheme
3. Run → Arguments → Environment Variables
4. Add:
   - Name: `BACKEND_URL`
   - Value: `https://your-app-name.up.railway.app/api`

### Option 2: Hardcode (Quick Test)

Edit `ReferralManager.swift`:
```swift
private var baseURL: String {
    return "https://your-app-name.up.railway.app/api"
}
```

---

## Alternative: Render.com (Another Free Option)

1. Go to [render.com](https://render.com)
2. "New Web Service" → Connect GitHub
3. Choose repository
4. Root directory: `backend`
5. Build command: `npm install && npx prisma generate`
6. Start command: `npm start`
7. Add PostgreSQL database
8. Copy URL → Use in iOS

---

## Quick Summary

**What you need to do:**

1. ✅ Sign up for Railway.app
2. ✅ Deploy backend (GitHub or CLI)
3. ✅ Add PostgreSQL database
4. ✅ Run migrations (`npx prisma migrate deploy`)
5. ✅ Run `node create-promo.js`
6. ✅ Copy your backend URL
7. ✅ Add URL to Xcode environment variables

**Your Backend URL Format:**
`https://your-project.up.railway.app/api`

**Your Promo Codes:**
- `BODAIApropirty` → 90% off 🔥
- `BODAIAsubject` → 50% off 💎
- `NOTWORTHYGIFT` → 10% off 🎁
- `PCPOSLAUNCH` → 20% off 🚀

---

**Need help?** Railway has great docs: [docs.railway.app](https://docs.railway.app)
