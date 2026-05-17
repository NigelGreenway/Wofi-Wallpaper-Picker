# Wofi Wallpaper Picker

This Wofi widget allows for previewing multiple wallpapers and choosing one to be set on Wayland setups.

The wallpapers are set by using a config file to point to what's available on your machine.

![alt text](assets/screenshot.png "Wofi Wallpaper Picker")

### Dependencies

 - `magick`
 - `wofi`

### Installation

1. Clone the repo
2. Run `cp ./config.dist ~/.config/wallpaper-picker/config`
3. Make the script executable
```$ chmod +x wofi-wallpaper-selector.sh```
4. Run the script

The script checks `WALLPAPER_DIR` for wallpapers, and then display's them via wofi.

### Usage

You can set this widget to an alias on your shell, or add it to a module on waybar, your choice really.

### Available options

 - `INSTALL_DIR`: The directory that this widget is installed, this allows for automatically picking up the config and styling files for wofi to render nicely
 - `WALLPAPER_DIR`: The directory of where you keep your wallpapers
 - `CACHE_DIR`: The cache of image previews of your wallpapers to be displayed in the picker
 - `THUMBNAIL_WIDTH`
 - `THUMBNAIL_HEIGHT`
 - `NOTIFICATION_LEVEL`: Either `0` or `1`, this sets the noise. If it's set to `0`, then only error's will be sent

### Special Thanks

Claude :)
