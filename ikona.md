# MySTT - Specyfikacja ikony aplikacji

## Wymagania techniczne

| Rozmiar logiczny | Skala | Rozmiar w pikselach | Użycie |
|---|---|---|---|
| 16x16 | 1x | 16px | Menu bar, Dock (mały) |
| 16x16 | 2x | 32px | Menu bar, Dock (Retina) |
| 32x32 | 1x | 32px | Finder list view |
| 32x32 | 2x | 64px | Finder list view (Retina) |
| 128x128 | 1x | 128px | Finder icon view |
| 128x128 | 2x | 256px | Finder icon view (Retina) |
| 256x256 | 1x | 256px | Finder preview |
| 256x256 | 2x | 512px | Finder preview (Retina) |
| 512x512 | 1x | 512px | App Store |
| 512x512 | 2x | 1024px | App Store (Retina) |

## Format

- **Plik źródłowy**: 1 plik PNG **1024x1024 px**, RGBA, 72 DPI
- **Bez zaokrąglonych rogów** - macOS automatycznie zaokrągla
- **Bez cienia** - macOS automatycznie dodaje
- **Bez przezroczystości na krawędziach** - pełne tło

## Generowanie wszystkich rozmiarów z jednego pliku

```bash
# Umieść icon_1024.png w katalogu projektu, następnie:
cd /Users/igor.3.wolak.external/Downloads/MySTT/MySTT/MySTT/Assets.xcassets/AppIcon.appiconset

ICON="/sciezka/do/icon_1024.png"

sips -z 16 16 "$ICON" --out icon_16x16.png
sips -z 32 32 "$ICON" --out icon_16x16@2x.png
sips -z 32 32 "$ICON" --out icon_32x32.png
sips -z 64 64 "$ICON" --out icon_32x32@2x.png
sips -z 128 128 "$ICON" --out icon_128x128.png
sips -z 256 256 "$ICON" --out icon_128x128@2x.png
sips -z 256 256 "$ICON" --out icon_256x256.png
sips -z 512 512 "$ICON" --out icon_256x256@2x.png
sips -z 512 512 "$ICON" --out icon_512x512.png
sips -z 1024 1024 "$ICON" --out icon_512x512@2x.png
```

Po wygenerowaniu zaktualizuj `Contents.json`:
```json
{
  "images": [
    {"idiom":"mac","scale":"1x","size":"16x16","filename":"icon_16x16.png"},
    {"idiom":"mac","scale":"2x","size":"16x16","filename":"icon_16x16@2x.png"},
    {"idiom":"mac","scale":"1x","size":"32x32","filename":"icon_32x32.png"},
    {"idiom":"mac","scale":"2x","size":"32x32","filename":"icon_32x32@2x.png"},
    {"idiom":"mac","scale":"1x","size":"128x128","filename":"icon_128x128.png"},
    {"idiom":"mac","scale":"2x","size":"128x128","filename":"icon_128x128@2x.png"},
    {"idiom":"mac","scale":"1x","size":"256x256","filename":"icon_256x256.png"},
    {"idiom":"mac","scale":"2x","size":"256x256","filename":"icon_256x256@2x.png"},
    {"idiom":"mac","scale":"1x","size":"512x512","filename":"icon_512x512.png"},
    {"idiom":"mac","scale":"2x","size":"512x512","filename":"icon_512x512@2x.png"}
  ],
  "info": {"author":"xcode","version":1}
}
```

## Rekomendacje wizualne

- **Motyw**: mikrofon z falą dźwiękową lub bubble z tekstem
- **Kolory**: ciemnoniebieski/fioletowy gradient (dobrze widoczny na jasnym i ciemnym menu bar)
- **Styl**: prosty, minimalistyczny, rozpoznawalny nawet w 16x16
- **Bez tekstu** - za mały w menu bar
- **Kontrast**: wyraźny kontrast z tłem menu bar (jasnym i ciemnym)
