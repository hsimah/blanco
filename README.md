# blanco
A repository of configuration for my daily driver machine, managed with [GNU Stow](https://www.gnu.org/software/stow/).

## Structure

Packages live under `home/`, each mirroring the path they should occupy relative to `$HOME`:

```
home/
  fish/.config/fish/
  kitty/.config/kitty/
  micro/.config/micro/
  chromium/.config/chromium/
```

## Adding a new package

`add-package.sh` moves an existing `~/.config/<package>` into the repo, stows it, and stages it for commit:

```bash
./add-package.sh <package-name>
```

Then review the staged files and commit:

```bash
git diff --cached
git commit -m "Add <package-name> config"
```

## Usage

Install a package by stowing it into `$HOME`:

```bash
stow -Rv -t ~ fish
```

Remove a package:

```bash
stow -Rv -t ~ --delete fish
```

## Packages

| Package | Config location |
|---------|----------------|
| fish | `~/.config/fish/` |
| kitty | `~/.config/kitty/` |
| micro | `~/.config/micro/` |
| chromium | `~/.config/chromium/` |
