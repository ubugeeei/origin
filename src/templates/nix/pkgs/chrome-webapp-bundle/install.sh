app_dir="$out/Applications/@APP_NAME@.app"
mkdir -p "$app_dir/Contents/MacOS"

cat > "$app_dir/Contents/Info.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
  <dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleExecutable</key>
    <string>@APP_NAME@</string>
    <key>CFBundleIdentifier</key>
    <string>@BUNDLE_ID@</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>@APP_NAME@</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
  </dict>
</plist>
EOF

cat > "$app_dir/Contents/MacOS/@APP_NAME@" <<EOF
#!/bin/sh
exec /usr/bin/open -na "Google Chrome" --args --app='@URL@'
EOF
chmod +x "$app_dir/Contents/MacOS/@APP_NAME@"
