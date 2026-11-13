//@ pragma UseQApplication
import Quickshell

ShellRoot {
  Wallpaper {}
  Bar {}
  Osd { id: osd }
  Audio { osd: osd }
  Menu {}
  Polkit {}
  Lock {}
}
