# Legal Pages for Magical Stories

This directory contains the Terms of Use and Privacy Policy pages for the Magical Stories iOS app, designed to be hosted on Firebase Hosting.

## 📋 Contents

- `terms-of-use.html` - Comprehensive Terms of Use document
- `privacy-policy.html` - Detailed Privacy Policy with COPPA compliance  
- `index.html` - Landing page with links to legal documents
- `firebase.json` - Firebase Hosting configuration
- `.firebaserc` - Firebase project configuration

## 🚀 Deployment Instructions

### Prerequisites
1. Install Firebase CLI: `npm install -g firebase-tools`
2. Login to Firebase: `firebase login`
3. Create a Firebase project (or use existing one)

### Initial Setup
1. Update `.firebaserc` with your Firebase project ID:
   ```json
   {
     "projects": {
       "default": "your-firebase-project-id"
     }
   }
   ```

2. Initialize Firebase Hosting (if not already done):
   ```bash
   cd legal-pages
   firebase init hosting
   ```

### Deploy to Firebase
```bash
cd legal-pages
firebase deploy --only hosting
```

Your legal pages will be available at:
- `https://your-project-id.web.app/`
- `https://your-project-id.firebaseapp.com/`

### Custom Domain (Optional)
You can set up a custom domain like `legal.magicalstories.app`:
1. Go to Firebase Console > Hosting
2. Click "Add custom domain"
3. Follow the DNS configuration steps

## 🔗 URL Structure

The Firebase configuration provides clean URLs:
- `/` - Legal landing page
- `/terms` - Terms of Use (redirects to `terms-of-use.html`)
- `/privacy` - Privacy Policy (redirects to `privacy-policy.html`)
- `/legal` - Same as landing page

## 📱 Integration with iOS App

Add these URLs to your iOS app's Settings:
```swift
// In your Settings view or constants file
struct LegalURLs {
    static let termsOfUse = "https://your-project-id.web.app/terms"
    static let privacyPolicy = "https://your-project-id.web.app/privacy"
}
```

Example SwiftUI implementation:
```swift
Link("Terms of Use", destination: URL(string: LegalURLs.termsOfUse)!)
Link("Privacy Policy", destination: URL(string: LegalURLs.privacyPolicy)!)
```

## 🛡️ Security Features

The Firebase configuration includes security headers:
- `X-Content-Type-Options: nosniff`
- `X-Frame-Options: DENY`
- `X-XSS-Protection: 1; mode=block`
- `Cache-Control: public, max-age=3600`

## 📝 Customization

### Update Company Information
Before deploying, update these placeholders in the HTML files:
1. Contact email addresses
2. Company jurisdiction/legal entity
3. App Store links
4. Specific feature descriptions

### Styling
The pages use inline CSS for easy customization. Key variables:
- Primary color: `#6366f1` (Indigo)
- Font family: Apple system fonts
- Responsive design for mobile/desktop

### Content Updates
When updating legal content:
1. Update the "Last Updated" date
2. Deploy the changes: `firebase deploy --only hosting`
3. Consider notifying users of significant changes

## 🔍 Legal Compliance

### COPPA Compliance
The Privacy Policy includes specific COPPA sections:
- Children under 13 protections
- Parental consent mechanisms
- Data collection limitations
- Parental rights and controls

### GDPR Compliance
Includes provisions for:
- Data subject rights
- Lawful basis for processing
- Data retention periods
- International transfers

### App Store Requirements
Meets Apple's App Store Review Guidelines:
- Clear subscription terms
- Privacy practices disclosure
- Child safety measures
- Data usage transparency

## 📞 Support Integration

The pages include multiple contact methods:
- General support: `support@magicalstories.app`
- Privacy questions: `privacy@magicalstories.app`
- COPPA requests: `coppa@magicalstories.app`

Make sure these email addresses are properly configured and monitored.

## 🔄 Maintenance

### Regular Reviews
- Review legal compliance quarterly
- Update for new features or data practices
- Monitor changes in privacy laws (COPPA, GDPR, CCPA)
- Check Firebase Hosting analytics for page usage

### Version Control
- Keep legal documents in version control
- Document significant changes
- Maintain previous versions for reference
- Track effective dates for each version

## 📊 Analytics

The landing page includes privacy-compliant analytics tracking. For more detailed analytics, consider:
- Firebase Analytics (already integrated in your app)
- Google Analytics 4 with privacy settings
- Simple server logs for page views

## ⚠️ Important Notes

1. **Legal Review**: Have these documents reviewed by legal counsel before deployment
2. **Regular Updates**: Keep documents current with app features and legal requirements  
3. **User Notification**: Notify users of significant policy changes
4. **Backup**: Keep local backups of all legal documents
5. **Testing**: Test all links and functionality before deployment

## 🚀 Quick Deploy Commands

```bash
# Navigate to legal pages directory
cd legal-pages

# Deploy to Firebase
firebase deploy --only hosting

# View deployment
firebase hosting:channel:open live
```

Your legal pages are now live and ready to be linked from your iOS app!