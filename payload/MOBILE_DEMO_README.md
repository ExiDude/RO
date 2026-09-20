# Ragnarok Core – Step 3 Gold Mobile

## Mobile-Basis
- Godot 4.7.1
- 720 × 1280 virtuelle Portrait-Auflösung im Mobile-Modus
- Sensor-Portrait
- Canvas Items + Expand
- explizite Touch-Verarbeitung; Touch→Mouse-Emulation bleibt aus
- Safe-Area-Margins über DisplayServer.get_display_safe_area()

## Bedienung
- Boden antippen → laufen
- Gegner antippen → auswählen + Auto-Approach + Auto-Attack
- TARGET → nächstes Ziel
- ATTACK → aktuelles Ziel angreifen / annähern
- CANCEL → Bewegung/Kampfkommando abbrechen
- F1–F9 → Hotbar
- F11/F12 auf Desktop → Save/Load

## Step-3-Polish
- MobileCamera mit Kartenlimits und Smooth Follow
- Mobile-Minimap
- South Field 1440 × 1920, sechs Porings
- Horror-"ill"-Ambience mit Pfad, Wasser, Wurzeln, Grab-/Schreinmotiven, Kerzen und roten Akzenten
- skalierbare SVG-UI für scharfe Smartphone-Darstellung
- Safe-Area-adaptives Player-/Target-HUD, Hotbar und Menü

## Test
Unter Windows zuerst TEST_RAGNAROK.bat ausführen.
START_MOBILE_DEMO.bat startet die Mobile-Vorschau. Ein Runtime-PASS gilt nur, wenn Godot tatsächlich ausgeführt wurde.
