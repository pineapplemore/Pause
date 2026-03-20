# AntiRepeat — Privacy, Support & Marketing (Netlify)

Deploy this folder to Netlify so the app has working links for:

- **Privacy Policy**: `https://YOUR-SITE.netlify.app/privacy.html`
- **Terms of Use (EULA)**: `https://YOUR-SITE.netlify.app/terms.html`
- **Support**: `https://YOUR-SITE.netlify.app/support.html`
- **About / Marketing**: `https://YOUR-SITE.netlify.app/marketing.html`

## Steps

1. Drag and drop this folder onto [Netlify Drop](https://app.netlify.com/drop) (or connect the repo and set publish directory to `website`).
2. Note your site URL (e.g. `https://antirepeat-legal.netlify.app`).
3. In the app, replace the placeholder in **PaywallView.swift**:
   - Find: `private let kLegalBaseURL = "https://YOUR-NETLIFY-SITE.netlify.app"`
   - Replace with your real URL (no trailing slash), e.g. `https://antirepeat-legal.netlify.app`
4. In App Store Connect, add the same URLs to your app metadata (Privacy Policy URL, and Terms of Use / EULA link in the description or EULA field).

## Optional

- Edit **support.html** to add your real support email or contact form.
- Edit **privacy.html** and **terms.html** if your lawyer or policy requires different wording.
