# Custom Notification Sounds

Place your custom notification sound files here.

## Required Files

### booking_confirmed.mp3
A short (1-3 seconds) sports/cricket themed sound for when a booking is confirmed.

Suggested sounds:
- Cricket bat hitting a ball ("thwack")
- Stadium crowd cheer
- Whistle + crowd combo

## How to Get the Sound File

1. Visit https://freesound.org or https://zapsplat.com (free account needed)
2. Search for "cricket bat hit" or "sports whistle cheer"
3. Download a short MP3 (1-3 seconds ideally)
4. Rename it to: `booking_confirmed.mp3`
5. Copy it into THIS folder: `android/app/src/main/res/raw/`
6. Do the same for the owner app at: `cricket_booking_owner/android/app/src/main/res/raw/`
7. Rebuild the app (flutter run)

## Note
- Filename must be lowercase with no spaces (only letters, numbers, underscores)
- Supported formats: .mp3, .wav, .ogg
- Keep it under 5 seconds for a good notification UX
