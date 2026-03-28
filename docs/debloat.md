# Debloat

This machine currently has these removable Apple-bundled apps in `/Applications`:

- `GarageBand.app` about 1.1 GB
- `iMovie.app` about 3.7 GB
- `Keynote.app` about 543 MB
- `Numbers.app` about 421 MB
- `Pages.app` about 460 MB

These are not part of your requested workstation setup, so they are reasonable removal candidates.

The following Apple apps also came up as unwanted on this machine, but they currently live in `/System/Applications` and are protected by SIP:

- `Books.app`
- `Chess.app`
- `FaceTime.app`
- `Games.app`
- `Journal.app`
- `Music.app`

With SIP enabled, this repository does not try to delete or hide those apps.

## Safe boundary

This cleanup script only targets these five apps.

It does **not** touch:

- Safari
- `Books`, `Chess`, `FaceTime`, `Games`, `Journal`, or `Music` in `/System/Applications`
- anything else in `/System/Applications`
- any Nix-managed app

## Remove them

```bash
./scripts/remove-unused-apple-apps.sh
```

Because they are owned by `root`, macOS will ask for your administrator password.

## Why the other Apple apps remain

On this Mac, `csrutil status` reports SIP as enabled, and the unwanted Apple apps above are installed under `/System/Applications`. That combination means ordinary removal or hiding is blocked at the OS level.
