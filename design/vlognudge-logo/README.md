# VlogNudge iOS brand assets

Colors: teal `#17665B` and warm cream `#F5F2EA`.
The mark combines a video frame/play symbol with an offset notification dot.

## Ready for Xcode

- `AppIcon.appiconset`: active modern catalog, 1024×1024 light, dark and grayscale tinted images; Xcode derives device sizes. Already installed in both app and widget targets.
- `Legacy/AppIcon.appiconset`: optional explicit iPhone/iPad/App Store slots for older workflows. Use **instead of**, never alongside, the universal set under the same name.
- `AllSizes/`: each light/dark/tinted appearance at 20, 29, 40, 58, 60, 76, 80, 87, 120, 152, 167, 180 and 1024 pixels.
- `VlogNudgeMark.imageset`: light/dark PDF vectors, preserves-vector-representation enabled. Installed in the app target. SwiftUI: `Image("VlogNudgeMark")`.
- `VlogNudgeMark@1x.png`, `@2x.png`, `@3x.png`: transparent 64-point raster mark.
- `logo.svg` + `logo.png`: horizontal wordmark. SVG text uses a generic serif stack, so typography may differ slightly by machine.
- `logo-icon.svg` + `logo-icon.png`: transparent square master.
- `app-icon-*.svg`: editable opaque app icon masters; square corners are intentional because iOS applies its own mask.

Regenerate from the repository root using `python3 scripts/generate_brand_assets.py` (Inkscape and Pillow required).
This package targets iOS/iPadOS; it does not add macOS, watchOS, or layered Icon Composer assets.
