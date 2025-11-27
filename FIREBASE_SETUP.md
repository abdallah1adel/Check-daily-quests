# 🔥 FIREBASE SETUP GUIDE
> **Quick 15-Minute Setup for Phase 2**

## Step 1: Create Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click "Add project"
3. Project name: **PCPOS-Companion**
4. (Optional) Enable Google Analytics: **Yes** (recommended)
5. Select or create Analytics account
6. Click "Create project"
7. Wait ~30 seconds for project creation

---

## Step 2: Add iOS App to Firebase

1. In Firebase Console, click iOS icon (or "Add app")
2. **Bundle ID**: `com.pcpos.PCPOScompanion`
   - ⚠️ **CRITICAL**: Must match exactly!
   - Verify in Xcode: Project → TARGETS → PCPOScompanion → General → Bundle Identifier
3. **App nickname**: PCPOS Companion (optional)
4. **App Store ID**: (leave blank for now)
5. Click "Register app"

---

## Step 3: Download Config File

1. Download `GoogleService-Info.plist`
2. **DO NOT** click "Next" yet
3. Locate the downloaded file (usually in ~/Downloads)

---

## Step 4: Add Config to Xcode

1. Open **Xcode**
2. In Project Navigator (left sidebar), right-click on `PCPOScompanion` folder
3. Select "Add Files to PCPOScompanion..."
4. Navigate to `GoogleService-Info.plist`
5. **CRITICAL SETTINGS**:
   - ✅ Check "Copy items if needed"
   - ✅ Select "PCPOScompanion" target
   - ✅ Create groups (not folder references)
6. Click "Add"
7. Verify file appears in project root (same level as `Info.plist`)

---

## Step 5: Enable Firebase Services

Back in Firebase Console:

### A. Authentication
1. Navigate to **Build → Authentication**
2. Click "Get started"
3. Enable sign-in methods:
   - ✅ **Email/Password** (click, toggle on, save)
   - ✅ **Google** (optional, for future)
   - ✅ **Facebook** (we'll configure this later)
4. Click "Save"

### B. Firestore Database
1. Navigate to **Build → Firestore Database**
2. Click "Create database"
3. Select **Start in test mode** (we'll add security rules later)
4. Choose region: **us-central** (or closest to you)
5. Click "Enable"

### C. Storage
1. Navigate to **Build → Storage**
2. Click "Get started"
3. Select **Start in test mode**
4. Click "Next", then "Done"

---

## Step 6: Verify Installation

In Firebase Console:
1. Go back to Project Overview
2. You should see:
   - ✅ iOS app registered
   - ✅ Authentication enabled
   - ✅ Firestore Database created
   - ✅ Storage bucket created

---

## Step 7: Test Connection (Agent Will Do)

Once you confirm the above steps are complete, tell the agent:
> "Firebase setup complete"

The agent will:
1. Add Firebase SDK to the project via SPM
2. Initialize Firebase in `AppDelegate`
3. Test the connection
4. Create Cloud Sync Manager

---

## Step 8: Facebook Integration (Optional - Later)

We'll tackle this in Phase 2B after Firebase is working.

For now, you need:
1. Go to [developers.facebook.com](https://developers.facebook.com/)
2. Create a new app
3. Save the **App ID** (we'll need it later)

---

## Troubleshooting

### "GoogleService-Info.plist not found"
- Make sure you dragged the file into the Xcode project (not just copied to folder)
- Verify it's in the project root
- Check "Copy items if needed" was selected

### "Bundle ID mismatch"
- In Firebase Console, go to Project Settings → Your apps
- Verify Bundle ID matches Xcode exactly: `com.pcpos.PCPOScompanion`
- If wrong, delete the iOS app and re-add it

### "Build errors after adding Firebase"
- Wait for the agent to add the SDK (don't add it manually)
- The agent will use Swift Package Manager to install cleanly

---

## What This Enables

Once Firebase is set up, you'll have:
- 🔐 **User Authentication** - Multi-user login
- 🗄️ **Cloud Database** - Sync biometrics across devices
- 📦 **Cloud Storage** - Store face/voice embeddings
- 📊 **Analytics** - Track usage patterns
- 🔔 **Push Notifications** - (Future feature)

---

**Estimated Time**: 10-15 minutes  
**Once done, notify the agent to continue Phase 2A implementation!**
