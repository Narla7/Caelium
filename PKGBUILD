# Maintainer: Caelium Team <caelium@example.com>
pkgname=caelium-system
pkgver=0.1.0
pkgrel=1
pkgdesc="Caelium desktop system configuration and tooling"
arch=('any')
url="https://github.com/caelium/caelium"
license=('MIT')
install=caelium-system.install
depends=(
  # base / boot / login
  base base-devel linux linux-firmware linux-headers
  grub efibootmgr os-prober dosfstools btrfs-progs cryptsetup
  ly
  arch-install-scripts

  # wayland / wm / shell
  hyprland hyprland-guiutils hyprland-preview-share-picker hyprpicker hyprsunset
  quickshell
  uwsm

  # terminal / apps
  kitty foot
  obsidian
  zen-browser-bin
  nautilus

  # larp tools
  fastfetch cava btop cmatrix

  # audio
  pipewire pipewire-alsa pipewire-pulse wireplumber alsa-utils pamixer

  # network / bluetooth
  networkmanager bluez bluez-tools bluez-utils

  # theme / wallpaper
  aether owe owe-lockfeed imagemagick

  # shell helpers
  jq perl inotify-tools socat wl-clipboard grim slurp brightnessctl upower
  gum

  # portals / auth
  xdg-desktop-portal-hyprland xdg-desktop-portal-gtk
  gnome-keyring polkit

  # fonts / icons
  noto-fonts noto-fonts-cjk noto-fonts-emoji
  ttf-jetbrains-mono-nerd-basic woff2-font-awesome yaru-icon-theme

  # basics
  bash-completion git curl wget unzip man-db man-pages

  # keyring so omarchy repo packages verify
  omarchy-keyring

  # installer tooling
  sudo gdisk parted
)
source=("caelium-src.tar.gz")
sha256sums=('SKIP')

package() {
  install -dm755 "$pkgdir/usr/share/caelium"
  install -dm755 "$pkgdir/usr/bin"
  install -dm755 "$pkgdir/etc/skel"
  install -dm755 "$pkgdir/etc/xdg"
  install -dm755 "$pkgdir/usr/share/licenses/$pkgname"

  # Copy vendored Omarchy-derived system files
  cp -a "$srcdir/caelium-src"/* "$pkgdir/usr/share/caelium/"

  # Symlink every executable in caelium/bin into /usr/bin so internal
  # omarchy-* helpers are on PATH alongside the caelium-* wrappers.
  for script in "$pkgdir/usr/share/caelium/bin/"*; do
    [[ -f $script && -x $script ]] || continue
    name=$(basename "$script")
    ln -sf "/usr/share/caelium/bin/$name" "$pkgdir/usr/bin/$name"
  done

  # Install default user dotfiles into /etc/skel (include hidden .config)
  cp -a "$pkgdir/usr/share/caelium/skel"/. "$pkgdir/etc/skel/"

  # ASCII logo used by the first-boot splash, show-logo and screensaver
  install -Dm644 "$srcdir/caelium-src/logo.txt" "$pkgdir/usr/share/caelium/logo.txt"

  # Install environment defaults
  install -Dm644 "$pkgdir/usr/share/caelium/etc/environment.d/60-caelium.conf" \
    "$pkgdir/etc/environment.d/60-caelium.conf"

  install -Dm644 "$startdir/LICENSE" "$pkgdir/usr/share/licenses/$pkgname/LICENSE"
}
