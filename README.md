# DK Assist Community

A Death Knight quality-of-life addon for World of Warcraft Retail / Midnight.

This is a community-maintained fork of **DK Assist** by ZachoWOW. It retains the original MIT license and attribution while adding 12.1 compatibility fixes and quality-of-life improvements.

## Features

- **Festering Scythe warning** — configurable action-bar or Cooldown Manager glow when Festering Strike changes to Festering Scythe; includes expiry timing, combat-start reminder, and optional Lesser Ghoul reminder.
- **Festering Scythe WA-Style alert** — a separate movable text alert with its own timing, font, outline, size, colour presets, live preview, green/yellow/red countdown, an optional EXPIRED state, and an optional Lesser Ghoul missing message.
- **Sudden Doom glows** — separate, configurable alerts for Death Coil and Epidemic when Sudden Doom procs. Necrotic Coil and Graveyard are also supported where applicable.
- **Sudden Doom WA-Style alert** — a separate movable and fully configurable text alert for Sudden Doom procs.
- **Putrefy hold warning** — configurable red cross or glow that tells you to hold Putrefy while Dark Transformation is unavailable. The warning hides during Dark Transformation and its Death Coil / Epidemic duration extensions.
- **Runic Power cap warning** — glow your Runic Power bar at a configurable threshold to prevent overcapping; supports Blizzard and compatible UI bars.
- **Death and Decay tracker** — tracks the active Death and Decay window with optional movable display controls.
- **Death and Decay buff reminder (Blood)** — optional glow on Death and Decay whenever the buff granted by standing in it is missing during combat. A short grace period keeps the buff Cleaving Strikes briefly re-grants when you step out from flickering the glow. Glows the action bar button, the Cooldown Manager icon, and the tracker at once. Requires Death and Decay in the Cooldown Manager, under either Tracked Buffs or Tracked Bars.
- **Soul Reaper control** — choose Blizzard's normal execute glow or suppress it entirely.
- **Four glow styles** — Pixel Glow, Autocast Shine, Button Glow, and Proc Border, with independent colours, presets, animation settings, thickness/particles, and opacity where relevant.
- **Action Bar or Cooldown Manager** — choose the target for Festering Scythe, Sudden Doom, and Putrefy warnings; includes Rescan Bars and Test tools.
- **Selectable standalone themes** — Classic plus Carbon Cyan, Graphite Red, Obsidian Lime, Frosted Blue, Slate Orange, and Unholy Green. Themes restyle the standalone window without changing Blizzard's AddOns settings page.
- **Modern settings controls** — themed dropdowns, sliders, value fields, and buttons in the standalone window, with live previews and Esc-to-close support.
- **Convenient access** — minimap button, addon compartment entry, HidingBar / DataBroker support, and the `/dka` command.

## Installation

1. Download the latest release ZIP.
2. Extract the `DKAssist` folder into `World of Warcraft/_retail_/Interface/AddOns/`.
3. Restart World of Warcraft or run `/reload`.

Open settings with `/dka`, or left-click the minimap icon.

## Credits and license

Original project: [DK Assist (Death Knight QoL)](https://www.curseforge.com/wow/addons/dk-assist-death-knight-qol) by ZachoWOW.

Special thanks to **Zachoe** for the original DKQoL / WA-Style alert concept, testing, and detailed feedback that helped shape the Festering Scythe and Sudden Doom text alerts in version 1.6.3.

This fork is distributed under the [MIT License](LICENSE). Original copyright notices and license terms are preserved.
