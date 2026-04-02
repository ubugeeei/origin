runHook preInstall

mkdir -p work
cd work
cp "$src" azooKey.pkg
xar -xf azooKey.pkg
mkdir payload
cd payload
gzip -dc ../azooKey-tmp.pkg/Payload | cpio -idm

mkdir -p "$out/Library/Input Methods"
cp -R azooKeyMac.app "$out/Library/Input Methods/azooKeyMac.app"

# Expose the input method bundle in app listings as well.
mkdir -p "$out/Applications"
ln -s "$out/Library/Input Methods/azooKeyMac.app" "$out/Applications/azooKeyMac.app"

runHook postInstall
