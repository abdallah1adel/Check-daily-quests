# Data Deletion Instructions for Facebook

**PCPOS Companion - User Data Deletion**

## For Users

If you used Facebook Login with PCPOS Companion and want to delete your data:

### Method 1: In-App Deletion
1. Open **PCPOS Companion** app
2. Go to **Profile**
3. Scroll to bottom and tap **"Delete Account"**
4. Confirm deletion
5. Your account and all associated data will be permanently deleted within 30 days

### Method 2: Web Portal
1. Visit [https://pcpos.app/delete-data](https://pcpos.app/delete-data)
2. Log in with your email or Facebook account
3. Click **"Delete My Data"**
4. Confirm deletion
5. You will receive a confirmation email

### What Gets Deleted
When you delete your account, we permanently remove:
- ✅ Your profile information (name, email, photo)
- ✅ All biometric data (face and voice embeddings)
- ✅ Social media connections (Facebook, Instagram)
- ✅ Usage history and preferences
- ✅ All cloud-stored data in Firebase

### Deletion Timeline
- **Immediate**: Your account is deactivated
- **Within 7 days**: All personal data is deleted from active databases
- **Within 30 days**: All backups and logs are purged

### Verification
After deletion, you will:
- No longer be able to log in
- Receive a confirmation email at your registered address
- Have all data removed from our systems (verifiable upon request)

---

## For Facebook App Review

### Data Deletion Callback URL
```
https://pcpos.app/api/facebook/data-deletion
```

### Request Format
```json
{
  "signed_request": "SIGNED_REQUEST_STRING"
}
```

### Response Format
```json
{
  "url": "https://pcpos.app/deletion-status/{confirmation_code}",
  "confirmation_code": "UNIQUE_CODE_12345"
}
```

### Implementation Details
Our data deletion callback:
1. Receives signed request from Facebook
2. Validates signature
3. Extracts Facebook User ID
4. Deletes all data associated with that Facebook ID
5. Returns confirmation code
6. Sends email notification to user

---

## Contact for Data Deletion Support

If you have issues deleting your data:
- **Email**: privacy@pcpos.app
- **Subject**: "Data Deletion Request"
- **Include**: Your email or Facebook ID

We respond within 48 hours.

---

**Last Updated**: November 27, 2025
