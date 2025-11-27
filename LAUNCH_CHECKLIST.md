# App Launch Checklist

Complete this checklist before submitting to the App Store.

## Pre-Build Configuration

### Code & Configuration
- [x] iOS deployment target set to 18.0
- [x] Subscription pricing updated to $22.99/month
- [x] Trial period set to 7 days
- [x] API key references use SecureConfig
- [ ] OpenAI API key configured in environment
- [ ] All features tested locally
- [ ] No hardcoded API keys in code

### Legal Documents
- [x] Privacy Policy created (PRIVACY_POLICY.md)
- [x] Terms of Service created (TERMS_OF_SERVICE.md)
- [ ] Documents hosted online (GitHub Pages/Netlify)
- [ ] URLs accessible and formatted correctly
- [ ] Contact email updated in both documents

## App Store Connect Setup

### Account Configuration
- [ ] Apple Developer account active ($99/year paid)
- [ ] Paid Applications Agreement accepted
- [ ] Banking information added
- [ ] Tax forms completed (W-9 or W-8BEN)
- [ ] Contact information current

### App Store Connect Record
- [ ] App created in App Store Connect
- [ ] Bundle ID matches: `com.pcpos.PCPOScompanion`
- [ ] App name reserved: "PCPOS Companion"
- [ ] Primary category set: Productivity
- [ ] Age rating completed: 4+

### Subscriptions
- [ ] Subscription group created: "Pro Access"
- [ ] Monthly subscription configured ($22.99)
  - Product ID: `com.PCPOScompanion.pro.monthly`
  - Duration: 1 month
  - Description filled
- [ ] Yearly subscription configured ($49.99)
  - Product ID: `com.PCPOScompanion.pro.yearly`
  - Duration: 1 year
  - Description filled
- [ ] Free trial period: 7 days (if offering intro offer)
- [ ] Subscription pricing approved for all territories

## Build & Upload

### Local Build Testing
- [ ] Build succeeds on physical device
- [ ] No compiler warnings (or acceptable ones documented)
- [ ] App launches without crashing
- [ ] Permissions (camera, microphone) request properly
- [ ] Voice recognition works
- [ ] Camera emotion detection works
- [ ] Subscription paywall displays correctly
- [ ] StoreKit sandbox testing completed

### Archive & Upload
- [ ] Create archive in Xcode (Product → Archive)
- [ ] Archive validation successful
- [ ] Upload to App Store Connect
- [ ] Processing complete in App Store Connect
- [ ] Build appears in "TestFlight" section

## TestFlight Beta Testing (Optional but Recommended)

- [ ] Internal testing group created
- [ ] At least 1 tester added
- [ ] Beta app information filled
- [ ] Test with sandbox subscription purchase
- [ ] Verify all core features work
- [ ] Collect feedback from testers

## App Store Submission

### Metadata
- [ ] App name: "PCPOS Companion"
- [ ] Subtitle: "Your AI Companion"
- [ ] Keywords entered (max 100 characters)
- [ ] Description written and formatted
- [ ] "What's New" for v1.0 entered
- [ ] Promotional text (optional)

### Screenshots
- [ ] iPhone 6.7" screenshots (3-10)
- [ ] iPhone 6.5" screenshots (3-10)
- [ ] Screenshots show actual app UI
- [ ] No misleading imagery
- [ ] Captions/text legible
- [ ] Subscription pricing visible in screenshots (if showing paywall)

### App Preview Video (Optional)
- [ ] 15-30 second video created
- [ ] Shows core features
- [ ] Portrait orientation
- [ ] Proper resolution for each device size

### URLs & Contact
- [ ] Privacy Policy URL: _______________
- [ ] Terms of Service URL: _______________
- [ ] Support URL: _______________
- [ ] Marketing URL (optional): _______________

### App Review Information
- [ ] First name entered
- [ ] Last name entered
- [ ] Phone number entered (with country code)
- [ ] Email address entered
- [ ] Demo account info (if needed): N/A
- [ ] Notes for reviewer written (see APP_STORE_METADATA.md)
- [ ] Attachments (if needed): None

### Version Release
- [ ] Version number: 1.0
- [ ] Build number: 1 (or higher)
- [ ] Release option selected:
  - [ ] Automatic release after approval
  - [ ] Manual release after approval

### Content Rights
- [ ] Copyright text: © 2025 [Your Name/Company]
- [ ] Trade representative contact info (for China)

## Pre-Submission Checks

### Technical Validation
- [ ] No crashes on launch
- [ ] No crashes during normal use
- [ ] Handles permissions gracefully if denied
- [ ] Falls back to free features if subscription not purchased
- [ ] "Restore Purchases" works correctly
- [ ] Subscription status syncs across devices
- [ ] Privacy disclosures accurate

### Compliance
- [ ] App uses camera/microphone only when user activates
- [ ] Privacy permissions clearly explained
- [ ] No hidden subscriptions or costs
- [ ] Free trial clearly communicated
- [ ] Subscription terms clearly displayed
- [ ] Refund policy accessible
- [ ] COPPA compliant (not collecting data from under 13)

### Content
- [ ] No inappropriate content
- [ ] No references to other platforms
- [ ] No promise of features not implemented
- [ ] Accurate representation of AI capabilities
- [ ] Clear about third-party services (OpenAI)

## Submit for Review

- [ ] All sections marked "Ready"
- [ ] Click "Submit for Review"
- [ ] Confirmation email received
- [ ] Status: "Waiting for Review"

## Post-Submission

### Monitor Status
- [ ] Check App Store Connect daily
- [ ] Respond to reviewer questions within 24 hours
- [ ] Address any rejection reasons promptly

### If Rejected
- [ ] Read rejection reason carefully
- [ ] Fix issues identified
- [ ] Re-test thoroughly
- [ ] Provide clarification in Resolution Center
- [ ] Resubmit

### If Approved
- [ ] Release app (manual or automatic)
- [ ] Monitor reviews
- [ ] Respond to user feedback
- [ ] Track analytics and subscriptions
- [ ] Plan updates and improvements

## Marketing Preparation (Optional)

- [ ] Landing page created
- [ ] Social media accounts set up
- [ ] Press kit prepared
- [ ] Launch announcement written
- [ ] Email list (if applicable)
- [ ] Influencer outreach (if applicable)

## Revenue Tracking

- [ ] App Store Connect analytics enabled
- [ ] Subscription reports reviewed
- [ ] Financial reports accessed
- [ ] First payout expected: ~45 days after first sale

---

## Quick Launch Timeline

**Assuming everything is ready:**

1. **Day 1**: Complete App Store Connect setup + Upload build
2. **Day 2-3**: TestFlight beta testing
3. **Day 4**: Submit for review
4. **Day 4-11**: App Review (average 2-7 days, can be up to 48 hours)
5. **Day 11+**: App goes live!

**Estimated Total**: 1-2 weeks from code-complete to live

---

## Support Resources

- **App Store Connect**: https://appstoreconnect.apple.com
- **Developer Portal**: https://developer.apple.com/account
- **App Store Guidelines**: https://developer.apple.com/app-store/review/guidelines/
- **Subscription Best Practices**: https://developer.apple.com/app-store/subscriptions/
- **Human Interface Guidelines**: https://developer.apple.com/design/human-interface-guidelines/
