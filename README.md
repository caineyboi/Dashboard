# Gladstone BOM Radar TV

Standalone GitHub Pages wrapper for AshtonAU/bom-radar-card v1.14.0.

## What this does

- No Home Assistant
- No Python server
- No laptop required after deployment
- Uses BOM's current public weather tiles
- Centre: Gladstone, Queensland
- Rain-rate radar animation
- 9 frames
- Five-minute data refresh
- Full-screen TV layout
- Controls auto-hide after inactivity

## Deploy

1. Create a GitHub repository.
2. Upload `index.html`.
3. Enable GitHub Pages for the repository.
4. Open the resulting `https://YOUR-USER.github.io/YOUR-REPO/` URL.

## Chromecast

The NC2-6A5 is a 2nd-generation Chromecast. It cannot independently open an arbitrary URL like an Android TV device.

For this Chromecast, a compatible sender/browser must cast the page to it. The GitHub Pages site itself needs no server.

If the goal is fully unattended startup without a sender device, this Chromecast model is the limiting hardware.

## Attribution/licensing

The radar card is AshtonAU/bom-radar-card, released under MIT.
It uses BOM weather data and BOM basemaps. Keep attribution enabled.

Project:
https://github.com/AshtonAU/bom-radar-card
