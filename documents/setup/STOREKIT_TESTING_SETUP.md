# StoreKit Testing Setup Guide

## 📋 Overview

This guide explains how to set up and use StoreKit testing in Xcode for the Magical Stories subscription system. The StoreKit configuration file allows you to test in-app purchases locally without needing real App Store Connect products or making actual purchases.

## 🛠️ Setup Steps

### 1. Add StoreKit Configuration to Xcode

1. **Open your Xcode project**
2. **Add the Configuration file to your project:**
   - Right-click on your project in Navigator
   - Select "Add Files to 'magical-stories'"
   - Navigate to `magical-stories-app/Configuration.storekit`
   - Make sure "Add to target" includes your main app target
   - Click "Add"

### 2. Configure Scheme for StoreKit Testing

1. **Edit your scheme:**
   - Go to Product → Scheme → Edit Scheme...
   - Select "Run" in the sidebar
   - Go to the "Options" tab
   - Under "StoreKit Configuration" dropdown, select "Configuration.storekit"
   - Click "Close"

### 3. Verify Configuration

The `Configuration.storekit` file includes:

```json
{
  "subscriptions": [
    {
      "productID": "com.magicalstories.premium.monthly",
      "displayPrice": "8.99",
      "recurringSubscriptionPeriod": "P1M",
      "introductoryOffer": {
        "numberOfPeriods": 1,
        "paymentMode": "free",
        "subscriptionPeriod": "P1W"
      }
    },
    {
      "productID": "com.magicalstories.premium.yearly",
      "displayPrice": "89.99", 
      "recurringSubscriptionPeriod": "P1Y",
      "introductoryOffer": {
        "numberOfPeriods": 1,
        "paymentMode": "free",
        "subscriptionPeriod": "P1W"
      }
    }
  ]
}
```

## 🧪 Testing Features

### Available Test Products

1. **Premium Monthly** (`com.magicalstories.premium.monthly`)
   - Price: $8.99/month
   - 7-day free trial
   - Monthly recurring

2. **Premium Yearly** (`com.magicalstories.premium.yearly`)
   - Price: $89.99/year (16% savings)
   - 7-day free trial  
   - Annual recurring

### Test Scenarios

#### 1. Successful Purchase Flow
```swift
// Test purchasing monthly subscription
let product = // Load from StoreKit
let result = try await product.purchase()
// Should complete successfully in simulator
```

#### 2. Free Trial Testing
- Both products include 7-day free trials
- Trial period starts immediately in test environment
- Can fast-forward time using Xcode's StoreKit testing controls

#### 3. Subscription Management
- Test subscription renewal
- Test subscription cancellation
- Test subscription expiration

#### 4. Restore Purchases
- Test restoring previous purchases
- Test family sharing scenarios

## 🎮 StoreKit Testing Controls

### In Xcode Simulator

1. **Open StoreKit Testing Controls:**
   - Debug → StoreKit → Manage Transactions
   - Or use the StoreKit transaction manager in Xcode

2. **Available Controls:**
   - View all transactions
   - Manually expire subscriptions
   - Clear purchase history
   - Fast-forward time
   - Test various failure scenarios

### Speed Up Testing

#### Fast-Forward Time
```
Debug → StoreKit → Options → Time Rate
```
- Set to "1 day = 1 minute" for rapid subscription testing
- Test trial expiration and renewal quickly

#### Clear Purchase History
```
Debug → StoreKit → Options → Clear Purchases
```
- Reset to fresh state for testing new user experience

## 🧩 Integration with App Code

### Product Loading
```swift
// Products will be loaded from Configuration.storekit
let products = try await Product.products(for: SubscriptionProduct.allProductIDs)
```

### Purchase Flow
```swift
// Purchase will use test environment
let result = try await product.purchase()
switch result {
case .success(let verification):
    // Handle successful test purchase
case .userCancelled:
    // Handle cancellation
case .pending:
    // Handle pending state
}
```

### Transaction Verification
```swift
// Transactions are automatically verified in test environment
for await result in Transaction.updates {
    let transaction = try checkVerified(result)
    // Process test transaction
}
```

## 🐛 Common Testing Issues

### Issue: Products Not Loading
**Solution:** 
- Verify Configuration.storekit is added to project target
- Check scheme is configured to use StoreKit configuration
- Ensure product IDs match exactly

### Issue: Purchase Flow Not Working  
**Solution:**
- Verify StoreKit configuration is selected in scheme
- Check Xcode console for StoreKit errors
- Use StoreKit Transaction Manager to debug

### Issue: Trial Period Not Working
**Solution:**
- Check introductoryOffer configuration in storekit file
- Use time acceleration to test trial expiration
- Verify trial logic in EntitlementManager

## 📊 Test Scenarios Checklist

### Basic Flow Testing
- [ ] Load products successfully
- [ ] Display product information correctly
- [ ] Complete purchase flow
- [ ] Handle purchase cancellation
- [ ] Restore previous purchases

### Subscription Testing  
- [ ] Start free trial
- [ ] Trial expiration handling
- [ ] Subscription renewal
- [ ] Subscription cancellation
- [ ] Expired subscription state

### Error Handling
- [ ] Network errors during purchase
- [ ] Invalid product scenarios
- [ ] Purchase verification failures
- [ ] Concurrent purchase attempts

### UI/UX Testing
- [ ] Paywall displays correctly
- [ ] Loading states during purchase
- [ ] Success/failure feedback
- [ ] Feature gating based on subscription status

## 🚀 Next Steps

After StoreKit testing is working:

1. **Implement PurchaseService** with StoreKit integration
2. **Create EntitlementManager** for subscription status
3. **Build Paywall UI** using test products
4. **Test feature gating** with subscription states
5. **Add comprehensive error handling**

## 📖 Additional Resources

- [Apple StoreKit Testing Documentation](https://developer.apple.com/documentation/xcode/setting-up-storekit-testing-in-xcode)
- [StoreKit 2 Programming Guide](https://developer.apple.com/documentation/storekit)
- [Testing In-App Purchases](https://developer.apple.com/documentation/storekit/in-app_purchase/testing_in-app_purchases)

---

**Note:** This configuration is for testing only. When ready for production, you'll need to configure actual products in App Store Connect and update your scheme to use the production StoreKit environment.