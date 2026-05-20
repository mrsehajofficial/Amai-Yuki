# Amai Yuki
> A premium, fluid, and lightweight real-time messaging frontend built with Flutter. Made with late nights and too much coffee.

I wanted to build a chat interface that doesn't just work, but actually *feels* good to use. No bloated third-party widgets, no lazy layouts. Just clean architecture, buttery-smooth micro-animations, and a highly responsive design.

---

## why this exists
Most messaging apps feel clunky, heavy, or just boring. With Amai Yuki, the goal was to create something premium. Every transition, every layout boundary, and every color choice is intentional. It's the frontend of a real-time system that bridges gorgeous HSL-tailored visuals with heavy background performance.

## the good stuff (features)
- **Fluid Direct & Group Chat:** Real-time message exchange powered by a robust socket service.
- **Visuals that Pop:** Dual-theme system (dark/light) styled with clean HSL curves, glassmorphic accents, and curated typography (Manrope/Inter).
- **Background Persistence:** Handles native push notifications through `flutter_local_notifications` and a dedicated `Workmanager` worker. It actually rings even when the app is suspended.
- **Custom Media Handling:** Custom in-app camera module and direct storage integrations that category-sort files instantly (no ugly, generic default pickers).
- **API Desugaring:** Standard Java 17 setups that run modern APIs smoothly even on older legacy Android devices.

## the stack & architecture
I'm a big believer in keeping logic completely separate from the UI. Here's how this is structured:
- **Core:** Flutter / Dart
- **State:** Provider (ChangeNotifiers that actually clean up after themselves)
- **Icons:** Phosphor Icons & Curated SVGs
- **Background Systems:** Workmanager & Local Notifications

## how to run this locally
If you want to spin this up on your machine, it's pretty straightforward:

1. **Clone the repo and get packages:**
   ```bash
   flutter pub get
   ```

2. **Keys & Signing:**
   You'll need your own `key.properties` and keystore files placed under the `android/` directory if you want to sign release builds. (Obviously, those private keys are left out of version control).

3. **Fire it up:**
   ```bash
   flutter run
   ```

---
*Built with care, pixels, and a lot of caffeine. If you like clean code and smooth interfaces, feel free to drop a star.*
