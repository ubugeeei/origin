# Accounts

## Git

Before your first commit, make sure `ORIGIN_GIT_USER_NAME`, `ORIGIN_GIT_USER_EMAIL`, and `ORIGIN_GITHUB_USER` are correct in `machine/local.env`.

Git behavior in this setup:

- GitHub and GitLab URLs are rewritten to SSH automatically.
- `gh` uses SSH.
- `glab` uses SSH.
- SSH config includes host entries for GitHub and GitLab.

Relevant repo config:

- Git and SSH defaults: [home/git.nix](../home/git.nix)
- machine-specific Git identity defaults: [machine/default.nix](../machine/default.nix)
- local machine override template: [machine/local.env.example](../machine/local.env.example)
- `glab` config file: [home/default.nix](../home/default.nix)

## SSH Keys

This setup expects SSH-first Git workflows for both GitHub and GitLab.

Generate a key if you do not already have one:

```bash
ssh-keygen -t ed25519 -C "you@example.com" -f ~/.ssh/id_ed25519
```

Add it to the macOS keychain-backed agent:

```bash
ssh-add --apple-use-keychain ~/.ssh/id_ed25519
```

Copy the public key when you need to paste it into a web UI:

```bash
pbcopy < ~/.ssh/id_ed25519.pub
```

Check what the agent has loaded:

```bash
ssh-add -L
```

Verify SSH access directly:

```bash
ssh -T git@github.com
ssh -T git@gitlab.com
```

What this repo already configures for SSH:

- `AddKeysToAgent yes`
- `Host github.com` with `User git`
- `Host gitlab.com` with `User git`
- `IdentitiesOnly yes` for both hosts

## GitHub

CLI login:

```bash
gh auth login --git-protocol ssh --web
```

Check login state:

```bash
gh auth status
```

Upload your SSH public key manually if needed:

```bash
gh ssh-key add ~/.ssh/id_ed25519.pub --title "origin workstation"
```

Notes:

- `gh auth login --git-protocol ssh --web` can detect and offer to upload an SSH key for you.
- Use `gh ssh-key add` when you want to upload the key explicitly yourself.
- This repo configures `gh` with `git_protocol: ssh`, `editor: zed`, and `prompt: enabled`.

Refresh the tracked GitHub profile icon asset:

```bash
./scripts/fetch-github-profile-icon.sh <github-username>
```

## GitLab

CLI login:

```bash
glab auth login --hostname gitlab.com --git-protocol ssh --web --use-keyring
```

Check login state:

```bash
glab auth status
```

Upload your SSH public key explicitly:

```bash
glab ssh-key add ~/.ssh/id_ed25519.pub --title "origin workstation" --usage-type auth
```

Notes:

- This repo configures `glab` with `git_protocol: ssh`, `browser: open`, `editor: zed`, and `pager: delta`.
- `glab` expects its config file to be mode `0600`; this repo now writes it that way.
- If you use GitLab SSH signing later, change `--usage-type` to match that workflow.

If you prefer web UI setup instead of CLI upload, the flow is:

1. Generate the SSH key.
2. Copy `~/.ssh/id_ed25519.pub`.
3. Add it in your GitHub or GitLab account SSH key settings.
4. Re-run the `ssh -T` verification commands.

## Google Workspace CLI

Installed command:

```bash
gam version
```

Initial setup depends on your Workspace admin flow. Typical start:

```bash
gam info domain
```

If this is a fresh `gam` setup, you will still need to place or generate the required Google API credentials and admin configuration after install.

## AWS CLI

Recommended initial setup:

```bash
aws configure sso
```

or:

```bash
aws configure
```

## Communication Apps

Sign into:

- Discord
- Slack
- Twitter
- Zoom
- Spotify

## Browser / Google Apps

Sign into:

- Chrome
- Gmail
- Google Calendar

Safari is built into macOS and remains available even though it is not installed by Nix.
