# Gulheefalhu View — Taste the Real

Production-ready static restaurant website for **Gulheefalhu View**, a Maldives Tandoor & Dessert House concept.

## Live site
After GitHub Pages is enabled from the repository root on `main`:

`https://naappe.github.io/gulheefalhuview/`

## Stack
- HTML5
- CSS3
- Vanilla JavaScript
- No build step
- GitHub Pages compatible

## Main features
- Responsive hospitality-focused design
- Real stock food / restaurant photography via Unsplash during pre-launch
- Signature dishes and full categorized menu
- Menu search
- Add-to-order basket saved in localStorage
- WhatsApp-ready order message workflow
- Reservation request workflow
- Mobile navigation and bottom quick actions
- Accessible gallery lightbox with keyboard and swipe controls
- Real-review placeholder (no fabricated testimonials)
- Restaurant JSON-LD, Open Graph and canonical metadata
- Reduced-motion support and image fallbacks

## Before public launch
Edit the `SITE` object at the top of `assets/j1.js`:

```js
const SITE = {
  phone: "",
  whatsapp: "",
  email: "",
  hours: "",
  map: "https://www.google.com/maps/search/?api=1&query=Gulheefalhu%2C%20Maldives",
  instagram: "",
  facebook: "",
  tiktok: ""
};
```

Use digits only for the WhatsApp number, including country code, e.g. `9607XXXXXX`.

The current photographs are launch-stage stock photography. Replace them with verified photographs of the actual restaurant and finished dishes when available.

## Brand
**Gulheefalhu View**  
**Taste the Real**
