# Referral System Setup Guide

## Quick Start

### 1. Install Dependencies

```bash
cd backend
npm install
```

### 2. Run Database Migration

```bash
npx prisma migrate dev --name add_referral_system
npx prisma generate
```

### 3. Create Initial Promo Code

```bash
node create-promo.js
```

This creates the "PCPOSLAUNCH" promo code (20% off, unlimited uses).

### 4. Start Backend Server

```bash
npm run dev
```

Server runs on `http://localhost:3000`

---

## Environment Setup

Add to `backend/.env`:

```env
DATABASE_URL="your_postgresql_connection_string"
PORT=3000
```

---

## Testing the Referral System

### Test Referral Code Generation

```bash
curl -X POST http://localhost:3000/api/referrals/generate \
  -H "Content-Type: application/json" \
  -d '{"userId": "test-user-123"}'
```

Response:
```json
{
  "code": "PCPOS-ABC123",
  "shareUrl": "https://pcposcompanion.app/ref/PCPOS-ABC123"
}
```

### Test Code Validation

```bash
curl -X POST http://localhost:3000/api/referrals/validate \
  -H "Content-Type: application/json" \
  -d '{"code": "PCPOSLAUNCH"}'
```

Response:
```json
{
  "valid": true,
  "type": "PROMO",
  "discount": {
    "type": "PERCENTAGE",
    "value": 20,
    "duration": "first_month"
  }
}
```

---

## iOS App Configuration

### Set Backend URL

Add to Xcode scheme environment variables:
- Name: `BACKEND_URL`
- Value: `https://your-backend-domain.com/api` (production)
- Or: `http://localhost:3000/api` (development)

Alternatively, update `ReferralManager.swift` with your backend URL.

---

## Creating More Promo Codes

Use Prisma Studio or create a custom admin endpoint:

```bash
npx prisma studio
```

Navigate to `PromoCode` and create new entries:
- **Code**: "SPECIAL50"
- **Type**: "PERCENTAGE" or "FIXED"
- **DiscountValue**: 50 (for 50% or $50)
- **MaxUses**: 100 (or null for unlimited)
- **ExpiresAt**: Set expiration date or null

---

## Discount Mechanics

### New User (Referee):
- Uses referral code → Gets 10% off first month
- Subscription: $22.99 → **$20.69** first month

### Existing User (Referrer):
- Each active referral → Gets $7.99/month off
- 3 active referrals → Pays **$15.00/month** ($22.99 - $7.99)
- Discount continues as long as referee stays subscribed

### Private Promo Code:
- Use "PCPOSLAUNCH" → Get 20% off
- Configurable in database

---

## App Store Connect Setup

### Configure Promotional Offers

1. Go to App Store Connect → Your App → Subscriptions
2. Create promotional offers:

**Offer 1: Referral Discount**
- Offer ID: `referral_discount`
- Type: Pay As You Go
- Duration: Unlimited
- Price: $15.00/month

**Offer 2: First Month 10% Off**
- Offer ID: `first_month_discount`
- Type: Pay As You Go  
- Duration: 1 billing period
- Price: $20.69/month

3. Generate offer codes or use programmatic offers

---

## Monitoring

### Check Referral Stats

```bash
curl http://localhost:3000/api/referrals/stats/user-id-here
```

### View All Promo Codes

```bash
npx prisma studio
```

Navigate to `PromoCode` table to see usage stats.

---

## Troubleshooting

### "Cannot find module '@prisma/client'"

Run:
```bash
cd backend
npx prisma generate
npm install
```

### Referral code not showing in app

1. Check backend is running
2. Verify `BACKEND_URL` environment variable
3. Check console logs for API errors

### Discount not applying

1. Ensure promotional offers are set up in App Store Connect
2. Verify StoreKit configuration matches offer IDs
3. Test with sandbox account

---

## Production Deployment

1. Deploy backend to hosting service (Railway, Render, etc.)
2. Update `BACKEND_URL` in iOS app
3. Create promotional offers in App Store Connect
4. Test end-to-end flow before launch
5. Monitor referral analytics

---

**Ready to launch!** 🚀
