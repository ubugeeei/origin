runHook preInstall

found=0
while IFS= read -r -d "" font; do
  found=1
  relative_path="${font#"$src"/}"
  install -Dm644 "$font" "$out/share/fonts/$relative_path"
done < <(find "$src" -type f \( -name '*.ttf' -o -name '*.ttc' -o -name '*.otf' \) -print0)

if [ "$found" -eq 0 ]; then
  echo "No font assets found in $src" >&2
  exit 1
fi

runHook postInstall
