# IAP Manual Test Cases Document

## Overview
This document provides comprehensive manual test cases for the In-App Purchase (IAP) subscription monetization feature in Magical Stories app. These test cases verify all subscription functionality, freemium limits, premium features, and user flows.

## Prerequisites
- iOS device with iOS 15.0+ or simulator
- Test Apple ID configured for Sandbox testing
- App Store Connect Sandbox environment configured
- Subscription products configured in App Store Connect:
  - `com.magicalstories.premium.monthly` - $8.99/month
  - `com.magicalstories.premium.yearly` - $89.99/year

## Test Environment Setup
1. Use Sandbox Apple ID for all testing
2. Enable Sandbox Environment in device Settings > App Store > Sandbox Account
3. Clear app data between test scenarios when needed
4. Document results for each test case

---

## Test Category 1: Free Tier Usage Limits

### TC-001: Initial Free User Experience
**Objective:** Verify new users get 3 free stories per month

**Steps:**
1. Install app with fresh user profile
2. Complete onboarding flow
3. Generate first story
4. Navigate to Library and verify story appears
5. Check usage indicator shows "2 stories remaining"

**Expected Result:**
- Story generation succeeds
- Usage counter shows 2/3 remaining
- No premium prompts appear
- Story appears in library

**Pass/Fail:** pass

---

### TC-002: Free Tier Limit Enforcement
**Objective:** Verify usage limit enforcement at 3 stories

**Steps:**
1. Continue from TC-001 or set up user with 2 stories generated
2. Generate second story, verify "1 story remaining"
3. Generate third story, verify "0 stories remaining"
4. Attempt to generate fourth story
5. Verify paywall appears with subscription options

**Expected Result:**
- First 3 stories generate successfully
- Usage counter decrements correctly
- 4th story attempt triggers paywall
- Paywall shows monthly ($8.99) and yearly ($89.99) options
- "Save 16% vs monthly" message appears for yearly plan

**Pass/Fail:** pass

---

### TC-003: Usage Limit Messaging
**Objective:** Verify appropriate messaging throughout usage progression

**Steps:**
1. Start with fresh user
2. Generate 1st story - check messaging
3. Generate 2nd story - check messaging  
4. Generate 3rd story - check messaging
5. Attempt 4th story - verify limit reached message

**Expected Result:**
- Progressive messaging shows remaining stories
- Clear indication when approaching limit
- Friendly upgrade suggestion appears
- Limit reached shows premium benefits

**Pass/Fail:** pass.

---

## Test Category 2: Subscription Purchase Flow

### TC-004: Monthly Subscription Purchase
**Objective:** Verify monthly subscription purchase flow

**Steps:**
1. Trigger paywall (attempt 4th story generation)
2. Select "Monthly Plan - $8.99/month"
3. Complete App Store purchase flow with test account
4. Verify purchase confirmation
5. Attempt to generate story immediately after purchase

**Expected Result:**
- Purchase flow completes successfully
- App recognizes subscription status immediately
- Story generation works without limits
- Premium features become available
- Usage counter shows "Unlimited" or similar

**Pass/Fail:** fail. After purchase, the app should not show any usage limits and should allow unlimited story generation. Subscription expiry date should be set to 1 month from purchase date.

---

### TC-005: Yearly Subscription Purchase
**Objective:** Verify yearly subscription purchase and savings message

**Steps:**
1. Fresh user at usage limit
2. Select "Yearly Plan - $89.99/year"
3. Verify "Save 16% vs monthly" message prominently displayed
4. Complete purchase
5. Verify subscription status and unlimited access

**Expected Result:**
- Savings calculation is accurate and prominent
- Purchase completes successfully
- All premium features unlock
- Subscription expiry date set correctly (1 year)

**Pass/Fail:** ___

---

### TC-006: Purchase Cancellation
**Objective:** Verify proper handling of cancelled purchases

**Steps:**
1. Initiate subscription purchase
2. Cancel during App Store flow
3. Verify app returns to paywall
4. Verify user remains on free tier
5. Verify usage limits still apply

**Expected Result:**
- App gracefully handles cancellation
- No subscription status change
- Free tier limits remain enforced
- User can retry purchase

**Pass/Fail:** ___

---

### TC-007: Purchase Failure Handling
**Objective:** Verify error handling for failed purchases

**Steps:**
1. Use test account with insufficient funds or disabled
2. Attempt subscription purchase
3. Verify error message display
4. Verify app state remains consistent
5. Test retry functionality

**Expected Result:**
- Clear error message displayed
- User remains on free tier
- Can attempt purchase again
- No partial subscription state

**Pass/Fail:** ___

---

## Test Category 3: Premium Feature Access

### TC-008: Growth Path Collections Access
**Objective:** Verify Growth Path Collections are premium-only

**Steps:**
1. Start with free user
2. Navigate to Collections
3. Attempt to access Growth Path Collections
4. Verify premium prompt appears
5. Purchase subscription and retry access

**Expected Result:**
- Free users see premium lock/prompt
- Premium users have full access
- Feature works correctly after subscription

**Pass/Fail:** ___

---

### TC-009: Multiple Child Profiles Feature
**Objective:** Verify multiple child profiles require premium

**Steps:**
1. Free user tries to add second child profile
2. Verify premium requirement message
3. Subscribe and add multiple profiles
4. Verify profile switching works correctly

**Expected Result:**
- Free users limited to 1 profile
- Premium users can add multiple profiles
- Profile switching maintains separate data

**Pass/Fail:** ___

---

### TC-010: Advanced Illustrations Feature
**Objective:** Verify advanced illustration options require premium

**Steps:**
1. Free user in story creation
2. Attempt to access advanced illustration options
3. Verify premium gate appears
4. Subscribe and verify advanced options available

**Expected Result:**
- Free users see basic illustration options only
- Premium gate explains advanced features
- Premium users access all illustration styles

**Pass/Fail:** ___

---

### TC-011: Priority Generation Feature
**Objective:** Verify premium users get priority story generation

**Steps:**
1. Compare generation times between free and premium users
2. During high load periods, verify premium users process faster
3. Check queue position messaging

**Expected Result:**
- Premium users experience faster generation
- Clear messaging about priority processing
- Consistent performance advantage

**Pass/Fail:** ___

---

## Test Category 4: Monthly Reset Functionality

### TC-012: Monthly Usage Reset
**Objective:** Verify monthly usage resets correctly

**Steps:**
1. User at 3/3 story limit
2. Manually trigger monthly reset (or wait for natural reset)
3. Verify usage counter resets to 0/3
4. Generate new story to confirm reset worked
5. Verify reset date updated

**Expected Result:**
- Usage counter resets to 0
- New stories can be generated
- Reset date tracking accurate
- No premium features lost during reset

**Pass/Fail:** ___

---

### TC-013: Cross-Month Boundary Testing
**Objective:** Verify reset works at month boundaries

**Steps:**
1. Set device date to last day of month
2. Use all 3 free stories
3. Advance date to first day of next month
4. Verify automatic reset occurs
5. Generate story to confirm reset

**Expected Result:**
- Automatic reset at month boundary
- No manual intervention required
- Usage tracking accurate across months

**Pass/Fail:** ___

---

## Test Category 5: Subscription Management

### TC-014: Transaction Observer Functionality
**Objective:** Verify TransactionObserver handles purchases from outside the app

**Steps:**
1. Subscribe using App Store directly (not in-app)
2. Launch app
3. Verify TransactionObserver detects external purchase
4. Check subscription status updates automatically
5. Verify expiration date calculated correctly

**Expected Result:**
- External purchases detected automatically
- Subscription status updates without user action
- Expiration date accurate (1 month/1 year from purchase)
- Premium features unlock immediately

**Pass/Fail:** ___

---

### TC-015: Restore Purchases
**Objective:** Verify purchase restoration works correctly

**Steps:**
1. Subscribe with test account
2. Delete and reinstall app
3. Launch app (should show free tier initially)
4. Use "Restore Purchases" option
5. Verify subscription status restored

**Expected Result:**
- Restore function available in settings
- Subscription status correctly restored
- All premium features re-enabled
- Usage limits removed

**Pass/Fail:** ___

---

### TC-016: Expiration Date Calculation
**Objective:** Verify accurate expiration date calculation for different subscription types

**Steps:**
1. Purchase monthly subscription and verify expiry = purchase date + 1 month
2. Purchase yearly subscription and verify expiry = purchase date + 1 year
3. Test with introductory offers (if available)
4. Verify calculations handle month boundaries correctly
5. Check leap year calculations for yearly subscriptions

**Expected Result:**
- Monthly subscriptions expire exactly 1 month from purchase
- Yearly subscriptions expire exactly 1 year from purchase
- Introductory periods calculated separately from regular periods
- Date calculations handle edge cases correctly

**Pass/Fail:** ___

---

### TC-017: Subscription Expiry Handling
**Objective:** Verify behavior when subscription expires

**Steps:**
1. Use expired test subscription
2. Verify app detects expiry
3. Check premium features become locked
4. Verify usage limits re-enable
5. Test renewal process

**Expected Result:**
- Graceful handling of expiry
- Features lock appropriately
- Clear renewal messaging
- Usage limits restore to free tier

**Pass/Fail:** ___

---

### TC-018: Subscription Status Synchronization
**Objective:** Verify subscription status syncs across app launches

**Steps:**
1. Subscribe and verify premium access
2. Force quit app
3. Relaunch app
4. Verify subscription status persists
5. Test feature access immediately

**Expected Result:**
- Status persists across launches
- No re-authentication required
- Premium features immediately available
- Consistent user experience

**Pass/Fail:** ___

---

### TC-019: Transaction Revocation Handling
**Objective:** Verify proper handling of revoked transactions

**Steps:**
1. Purchase subscription normally
2. Use Apple's Sandbox tools to revoke the transaction
3. Verify app detects revocation automatically
4. Check that premium features are disabled
5. Verify user is notified appropriately

**Expected Result:**
- Revoked transactions detected automatically
- Premium access removed immediately
- Clear messaging about subscription status
- User can repurchase if desired

**Pass/Fail:** ___

---

## Test Category 6: UI/UX Validation

### TC-020: Paywall Presentation
**Objective:** Verify paywall appears in correct contexts

**Steps:**
1. Test paywall triggers: usage limit, premium feature access, settings
2. Verify paywall design matches requirements
3. Check accessibility features
4. Test dismiss and retry flows

**Expected Result:**
- Paywall appears at appropriate times
- Design is user-friendly and clear
- Accessibility labels present
- Easy to understand and navigate

**Pass/Fail:** ___

---

### TC-021: Usage Indicator Display
**Objective:** Verify usage indicators are clear and accurate

**Steps:**
1. Check usage display in various app sections
2. Verify indicators update in real-time
3. Test visual design and clarity
4. Verify accessibility compliance

**Expected Result:**
- Usage clearly displayed throughout app
- Real-time updates when stories generated
- Visual design is intuitive
- Screen reader compatible

**Pass/Fail:** ___

---

### TC-022: Premium Feature Highlighting
**Objective:** Verify premium features are clearly marked

**Steps:**
1. Navigate through app as free user
2. Identify all premium feature indicators
3. Verify consistent visual treatment
4. Test tap behaviors on locked features

**Expected Result:**
- Premium features clearly identified
- Consistent visual design language
- Appropriate upgrade prompts
- No confusion about access levels

**Pass/Fail:** ___

---

## Test Category 7: Edge Cases and Error Scenarios

### TC-023: Network Connectivity Issues
**Objective:** Verify behavior during network issues

**Steps:**
1. Disable network during subscription purchase
2. Test app behavior with intermittent connectivity
3. Verify error messages and retry mechanisms
4. Test offline mode limitations

**Expected Result:**
- Graceful handling of network issues
- Clear error messages
- Automatic retry when possible
- Offline functionality preserved

**Pass/Fail:** ___

---

### TC-024: App Store Account Issues
**Objective:** Verify handling of various account states

**Steps:**
1. Test with account restrictions enabled
2. Test with parental controls active
3. Test with different country/region settings
4. Verify appropriate error handling

**Expected Result:**
- Clear messaging for account issues
- Appropriate fallback options
- Compliance with regional restrictions
- No app crashes or undefined states

**Pass/Fail:** ___

---

### TC-025: Concurrent Usage Scenarios
**Objective:** Verify app handles concurrent usage correctly

**Steps:**
1. Use app on multiple devices with same account
2. Generate stories simultaneously
3. Verify usage counting accuracy
4. Test subscription status sync

**Expected Result:**
- Accurate usage tracking across devices
- Subscription status syncs properly
- No race conditions or inconsistencies
- Graceful handling of conflicts

**Pass/Fail:** ___

---

## Test Category 8: Analytics and Tracking

### TC-026: Subscription Analytics Events
**Objective:** Verify analytics events fire correctly

**Steps:**
1. Monitor analytics during subscription flow
2. Verify all required events are tracked:
   - paywall_shown
   - product_viewed
   - purchase_started
   - purchase_completed
   - purchase_failed
   - feature_restricted
   - usage_limit_reached

**Expected Result:**
- All events fire at appropriate times
- Event data includes required parameters
- No duplicate or missing events
- Data accurately represents user actions

**Pass/Fail:** ___

---

### TC-027: Usage Analytics Tracking
**Objective:** Verify usage statistics are tracked correctly

**Steps:**
1. Generate stories and monitor usage tracking
2. Verify monthly reset analytics
3. Check premium feature usage tracking
4. Validate conversion funnel data

**Expected Result:**
- Accurate usage statistics
- Proper conversion tracking
- Monthly reset events recorded
- Feature usage properly attributed

**Pass/Fail:** ___

---

## Test Category 9: Accessibility and Localization

### TC-028: Accessibility Compliance
**Objective:** Verify subscription features are accessible

**Steps:**
1. Enable VoiceOver and test subscription flow
2. Verify all elements have appropriate labels
3. Test with increased text size
4. Verify color contrast compliance

**Expected Result:**
- All elements accessible via VoiceOver
- Clear and descriptive labels
- Scales properly with text size
- Meets accessibility guidelines

**Pass/Fail:** ___

---

### TC-029: Pricing Display Accuracy
**Objective:** Verify pricing displays correctly across regions

**Steps:**
1. Test pricing display in different locales
2. Verify currency formatting
3. Check savings calculations
4. Verify tax inclusion messaging

**Expected Result:**
- Correct pricing for user's region
- Proper currency formatting
- Accurate savings calculations
- Clear tax messaging where required

**Pass/Fail:** ___

---

## Test Category 10: Performance and Stability

### TC-030: Performance During Subscription Flow
**Objective:** Verify subscription flow performs well

**Steps:**
1. Monitor app performance during purchases
2. Test with low memory conditions
3. Verify background/foreground transitions
4. Check for memory leaks during repeated flows

**Expected Result:**
- Smooth performance throughout flow
- Graceful handling of low memory
- Proper state restoration
- No memory leaks or crashes

**Pass/Fail:** ___

---

### TC-031: Subscription Service Reliability
**Objective:** Verify subscription services are reliable

**Steps:**
1. Test repeated subscription checks
2. Verify service recovery after failures
3. Test timeout handling
4. Verify proper error recovery

**Expected Result:**
- Consistent service reliability
- Automatic recovery from failures
- Appropriate timeout values
- Clear error communication

**Pass/Fail:** ___

---

## Test Summary Report Template

### Test Execution Summary
- **Total Test Cases:** 31
- **Passed:** ___
- **Failed:** ___
- **Blocked:** ___
- **Not Executed:** ___

### Critical Issues Found
1. Issue: ___
   Severity: High/Medium/Low
   Impact: ___

### Recommendations
1. ___
2. ___
3. ___

### Sign-off
- **Tester:** ___
- **Date:** ___
- **Environment:** ___
- **App Version:** ___
- **Device/iOS Version:** ___

---

## Notes for Testers

### Important Testing Tips
1. Always use Sandbox environment for IAP testing
2. Clear app data between major test scenarios
3. Document exact error messages encountered
4. Test on multiple device types and iOS versions
5. Verify behavior during app backgrounding/foregrounding
6. Test with both strong and weak network connections
7. Test TransactionObserver by purchasing subscriptions outside the app (via App Store)
8. Verify expiration date calculations are accurate for different time zones
9. Test transaction revocation scenarios using Apple's Sandbox tools
10. **Test paywall auto-dismissal**: After successful purchase, verify paywall dismisses and story generation works immediately
11. **Test subscription status observation**: Verify form views react to subscription changes in real-time
12. **Test rapid status changes**: Purchase → Cancel → Purchase again scenarios

### Common Issues to Watch For
1. Subscription status not updating immediately
2. Usage counters not syncing across devices
3. Premium features accessible to free users
4. Incorrect pricing display
5. Analytics events not firing
6. Memory leaks during repeated operations
7. **Paywall reappearing after successful purchase** (Fixed in latest version)
8. **Form views not observing EntitlementManager changes** (Fixed in latest version)
9. **Transaction processing delays causing UI inconsistencies** (Addressed in latest version)

### Test Data Management
1. Keep track of test Apple IDs used
2. Document subscription states for each test account
3. Record any test environment issues
4. Maintain logs of purchase receipts

This document should be used in conjunction with automated tests and provides comprehensive coverage of all subscription monetization features for manual verification.