# Closet.AI

An iOS app that turns your wardrobe into a digital closet and suggests outfits from what you already own.

**Author:** Dhwani Chauhan

## Features

- **Digital closet** — Photograph clothes and organize them by category (top, bottom, shoes, outerwear, accessory) and color
- **On-device analysis** — VisionKit suggests category and dominant color when you add an item
- **AI outfit ideas** — Generate outfit combinations from your closet via OpenAI
- **Wishlist** — Save finds with a photo, description, and estimated price
- **Today’s Outfit widget** — Home Screen widget showing your latest suggestion
- **Onboarding** — Short first-run intro to the main flows

## Requirements

- Xcode 15+ (SwiftUI / SwiftData)
- iOS 17+
- An [OpenAI API key](https://platform.openai.com/api-keys) for outfit generation

## Setup

1. Clone the repo and open `ClosetAI.xcodeproj` in Xcode.
2. Copy the config template and add your API key:

   ```bash
   cp Config.example.swift ClosetAI/Config.swift
   ```

3. Edit `ClosetAI/Config.swift` and set your key:

   ```swift
   struct Config {
       static let aiAPIKey = "YOUR_OPENAI_API_KEY"
       static let aiAPIEndpoint = "https://api.openai.com/v1/chat/completions"
   }
   ```

   `ClosetAI/Config.swift` is gitignored — do not commit it.

4. Select the **ClosetAI** scheme, choose a simulator or device, and run (⌘R).

### Widget

The **ClosetAIWidget** target provides the “Today’s Outfit” widget. Add it from the Home Screen after installing the app. It reads the latest outfit snapshot shared by the main app.

## App structure

| Tab | Purpose |
|-----|---------|
| Closet | Browse, filter, and add clothing items |
| Outfits | Generate and browse AI outfit suggestions |
| Wishlist | Track items you want to buy |
| Settings | App info |

### Key directories

```
ClosetAI/
  Models/          # ClothingItem, Outfit, WishlistItem (SwiftData)
  Services/        # AI outfits, image analysis, item descriptions, widget store
  Views/           # Closet, Outfits, Wishlist, Settings, onboarding
ClosetAIWidget/    # Today’s Outfit WidgetKit extension
Config.example.swift
```

## Privacy & data

- Clothing photos and metadata are stored locally with SwiftData.
- Category/color suggestions run on-device with Vision.
- Outfit generation sends closet item descriptions (not raw photos) to the configured OpenAI endpoint.

## Version

Closet.AI v0.1
