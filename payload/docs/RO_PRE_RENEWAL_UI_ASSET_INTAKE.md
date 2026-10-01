# Originalressourcen für das RO-Pre-Renewal-UI

## Warum die Umsetzung hier bewusst beginnt

Die gelieferten Referenzbilder zeigen das klassische Desktop-UI, das Projekt enthält
derzeit aber nur eine eigens gezeichnete Mobile-/Horror-Oberfläche unter
`assets/ui/ill_mobile`. Ein Nachzeichnen der Fenster aus dem Screenshot würde
Proportionen, Zustände und transparente Kanten unnötig ungenau machen. Deshalb
werden **vor dem Bau größerer Ersatzgrafiken** die Originalressourcen eines legal
vorhandenen Ragnarok-Clients angefordert.

Bitte keine komplette GRF und keine Zugangsdaten einchecken. Benötigt wird ein
lokal extrahierter, unveränderter Ausschnitt. Dateinamen und Unterordner müssen
erhalten bleiben, weil Clientversionen unterschiedliche Namen und Aufteilungen
verwenden. Koreanische Pfade bitte als UTF-8 manifestieren oder zusätzlich die
ursprünglichen Rohpfade in einer Dateiliste angeben.

## Zuerst bereitzustellende Dateien

### Priorität A – vollständiger Skin (zwingend)

Aus dem eigenen Client den **kompletten Ordner des tatsächlich verwendeten
Skins** bereitstellen, üblicherweise:

```text
skin/<Skinname>/**
```

Bei Clients ohne separaten Skin-Ordner stattdessen den vollständigen Inhalt des
UI-Texture-Ordners aus `data.grf`/`rdata.grf` extrahieren. Je nach Encoding wird
dieser als einer der folgenden Pfade angezeigt:

```text
data/texture/유저인터페이스/**
data/texture/À¯ÀúÀÎÅÍÆäÀÌ½º/**
```

Nicht nur die im Screenshot sichtbaren Bitmaps auswählen: benötigt werden auch
Hover-/Pressed-/Disabled-Zustände, Tabs, Scrollbars, Checkboxen, Pfeile,
Schließen-/Minimieren-Schaltflächen, Rahmenstücke und Masken. Akzeptierte
Quellformate sind BMP, TGA und PNG; Alphakanal bzw. Color-Key darf beim Export
nicht vorab geglättet werden.

### Priorität B – Icons und Kartenbilder (zwingend für inhaltstreue Fenster)

```text
data/texture/아이템/**              # Inventar-/Equipment-Icons
data/texture/ÀÌÁ¦ÀÌÅÛ/**           # derselbe Ordner in älteren Codepages
data/sprite/아이템/**               # alternative Item-Sprites alter Clients
data/texture/collection/**          # große Item-/Collection-Bilder, falls vorhanden
data/texture/map/**                 # Minimap-Bitmaps und Kartenindikatoren
data/texture/effect/**              # nur UI-Cursor/Marker, keine Welteffekte nötig
```

Zusätzlich bitte die Tabellen mitliefern, die IDs auf Dateinamen und deutsche
Anzeigenamen abbilden (nur soweit im eigenen Client vorhanden):

```text
data/idnum2itemdisplaynametable.txt
data/idnum2itemresnametable.txt
data/num2itemdisplaynametable.txt
data/num2itemresnametable.txt
data/iteminfo*.lub
data/skillnametable.txt
data/skilldesctable.txt
data/skillinfo*.lub
```

### Priorität C – Schrift und Cursor (erwünscht)

* Die vom Client konfigurierte Bitmap-/TrueType-Schrift samt Lizenzhinweis, falls
  sie redistributierbar ist.
* UI-Cursor, Drag-and-drop-Cursor und Zielmarker aus dem Skin/UI-Texture-Ordner.
* Falls die Originalschrift nicht weitergegeben werden darf: Name, Punktgröße und
  ein Screenshot mit 100-%-Windows-Skalierung. Dann wird eine rechtlich nutzbare
  metrisch ähnliche Pixel-/Bitmap-Schrift verwendet.

### Begleitinformationen

Bitte zusammen mit den Dateien angeben:

1. Client-/Skinname, ungefähres Build-Datum und Sprache.
2. Referenzauflösung und Windows-DPI-Skalierung (bevorzugt 640 × 480 bei 100 %).
3. Transparenzregel des Extraktors (Alphakanal oder Color-Key, inklusive Farbe).
4. Eine UTF-8-Dateiliste mit relativen Pfaden und SHA-256-Prüfsummen.

Beispiel zum Erzeugen der Liste in PowerShell:

```powershell
Get-ChildItem -Recurse -File .\ro_ui_source |
  ForEach-Object {
    "{0}  {1}" -f (Get-FileHash $_.FullName -Algorithm SHA256).Hash,
      $_.FullName.Substring((Resolve-Path .\ro_ui_source).Path.Length + 1)
  } | Set-Content -Encoding utf8 .\ro_ui_source\SHA256SUMS.txt
```

## Verbindliche Zuordnung ins Projekt

Die Originale werden unverändert unter `source/` archiviert. Konvertierte oder
beschnittene Laufzeitdateien liegen getrennt unter `runtime/`; dadurch bleiben
Herkunft und Bearbeitung nachvollziehbar.

| Originaldatei/-ordner | UI-Element | Zielpfad im Projekt |
|---|---|---|
| `skin/<Skinname>/**` | Fensterrahmen, Titelleisten, Tabs, Buttons, Scrollbars, Checkboxen, Balken | `assets/ui/ro_original/source/skin/<Skinname>/**` |
| `data/texture/(유저인터페이스)/**` | fehlende globale UI-Teile, Cursor, Marker | `assets/ui/ro_original/source/interface/**` |
| Skin-Hintergrundteile | skalierbare Panels als `StyleBoxTexture`/9-Slice | `assets/ui/ro_original/runtime/panels/**` |
| Skin-Buttonzustände | Normal/Hover/Pressed/Disabled | `assets/ui/ro_original/runtime/buttons/**` |
| Skin-Balken | HP, SP, Base-/Job-EXP, Gewicht | `assets/ui/ro_original/runtime/bars/**` |
| Skin-Tabs/Checkboxen/Pfeile | Inventarfilter, Optionen, Party/Freunde, Status | `assets/ui/ro_original/runtime/widgets/**` |
| `data/texture/(아이템)/**` | Inventar-, Equipment- und Hotbar-Icons | `assets/ui/ro_original/source/items/**` |
| normalisierte Item-Icons | zur Laufzeit nach Ressourcen-ID geladen | `assets/ui/ro_original/runtime/items/**` |
| Skill-Icon-Dateien aus UI-/Skill-Unterordnern | Skillfenster und Hotbar | `assets/ui/ro_original/source/skills/**` bzw. `runtime/skills/**` |
| `data/texture/map/**` | echte Kartenansicht der Minimap | `assets/ui/ro_original/source/maps/**` |
| Tabellen/LUB-Dateien | ID → Resource → deutscher Name | `data/ro_client_tables/**` |
| zulässige Originalschrift | kompakte UI-Typografie | `assets/fonts/ro_original/**` |

Die tatsächlichen Basenames werden erst nach Sichtung in einem maschinenlesbaren
Manifest festgeschrieben; pauschales Umbenennen vor der Übergabe würde die
ID-Zuordnung zerstören.

## Importregeln für Godot 4.7.1

* Texturfilter **Nearest**, Mipmaps aus, keine verlustbehaftete Kompression.
* Keine vorzeitige Skalierung. Desktop zunächst in der nativen Pixelgröße des
  gelieferten Skins; ganzzahlige UI-Skalierungsstufen bevorzugen.
* Rahmen als `StyleBoxTexture` mit individuell vermessenen Texture-/Patch-Margins,
  nicht mit einem pauschalen Randwert.
* Icon-Atlanten als `AtlasTexture`; Einzelbilder nicht weichzeichnen.
* Transparente BMP-Color-Keys einmal reproduzierbar in PNG konvertieren und den
  Schlüssel im Manifest dokumentieren.
* Originale in `source/` nie überschreiben. Jede Ableitung bekommt Quellpfad,
  Hash, Ausschnitt, Color-Key und Slice-Ränder im Manifest.

## Ergebnis der Bestandsanalyse

Der aktuelle Patchstand enthält bereits dynamische Abfragen für Name, Job,
Level, HP/SP, EXP und Zeny im Player-HUD sowie dynamische Hotbar-Slots. Diese
Schnittstellen werden beibehalten. Die gegenwärtige Darstellung verwendet jedoch
große, ornamentale SVGs und ist nicht die helle, kompakte Pre-Renewal-Skin der
Referenz.

Mehrere von `core/main.tscn` referenzierte Basisszenen und -skripte (unter
anderem Inventar, Equipment, Dialog und das zentrale Fenster-System) sind in
diesem Repository-Payload nicht enthalten. Für die vollständige Datenbindung und
einen belastbaren Laufzeittest wird daher außerdem der vollständige Projektstand
benötigt, auf den dieser Payload angewendet wird. Bis dahin dürfen keine
Beispielwerte als vermeintliche Charakterdaten eingebaut werden.

## Umsetzung nach Eingang der Ressourcen

1. Hashes, Dateiformate, Transparenz und Lizenzen prüfen; Assetmanifest erzeugen.
2. Gemeinsames `Theme` und wiederverwendbare verschiebbare Fensterkomponente mit
   Fokus-/Z-Order, Minimieren, Schließen und Viewport-Clamping erstellen.
3. Basic Info, Menüleiste und F1–F9-Hotbar pixelgenau umsetzen.
4. Inventar, Equipment, Status, Skills sowie Optionen auf bestehende Controller
   und Signale binden.
5. Party/Freunde, Chat und Raumerstellung an die vorhandenen Runtime-Daten binden;
   nicht vorhandene Backend-Funktionen klar als solche kapseln.
6. Minimap mit echter Kartenbitmap und dynamischen Spieler-/Party-Markern bauen.
7. Bei 640 × 480, 800 × 600, 1280 × 720 und Mobile-Safe-Areas auf Überlappung,
   Clipping, Drag-Grenzen und ganzzahlige Pixelskalierung testen.

