{
  stdenvNoCC,
  lib,
}:
{
  appName,
  bundleId,
  url,
}:
stdenvNoCC.mkDerivation {
  pname = lib.strings.sanitizeDerivationName (lib.strings.toLower appName);
  version = "1.0.0";

  dontUnpack = true;

  installPhase = ''
    app_dir="$out/Applications/${appName}.app"
    mkdir -p "$app_dir/Contents/MacOS"

    cat > "$app_dir/Contents/Info.plist" <<EOF
    <?xml version="1.0" encoding="UTF-8"?>
    <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
    <plist version="1.0">
      <dict>
        <key>CFBundleDevelopmentRegion</key>
        <string>en</string>
        <key>CFBundleExecutable</key>
        <string>${appName}</string>
        <key>CFBundleIdentifier</key>
        <string>${bundleId}</string>
        <key>CFBundleInfoDictionaryVersion</key>
        <string>6.0</string>
        <key>CFBundleName</key>
        <string>${appName}</string>
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

    cat > "$app_dir/Contents/MacOS/${appName}" <<EOF
    #!/bin/sh
    exec /usr/bin/open -na "Google Chrome" --args --app='${url}'
    EOF
    chmod +x "$app_dir/Contents/MacOS/${appName}"
  '';

  meta = with lib; {
    description = "${appName} launcher bundle for macOS";
    platforms = platforms.darwin;
    sourceProvenance = with sourceTypes; [ binaryNativeCode ];
    license = licenses.mit;
  };
}
