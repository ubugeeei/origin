echo "Setting up /Library/Input Methods..." >&2
mkdir -p /Library/Input\ Methods
find @APP_ENV@/Library/Input\ Methods -maxdepth 1 -type l | while read -r im; do
  src="$(readlink "$im")"
  im_name="$(basename "$src")"
  rm -rf "/Library/Input Methods/$im_name"
  /usr/bin/ditto "$src" "/Library/Input Methods/$im_name"
done
