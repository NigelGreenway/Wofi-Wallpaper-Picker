#!/usr/bin/env bash

_wwp_has() { command -v "$1" &>/dev/null; }

_wwp_notify_send() {
    [[ -z "$1" ]] && return 1

    if _wwp_has notify-send; then
        IFS='=' read -r key value <<< "$1"

        echo "$key: $value"

        if [ "$value" == "normal" ] && [ "$NOTIFICATION_LEVEL" -gt 0 ]; then
            notify-send "$@"
        fi

        if [ "$value" == "critical" ]; then
            notify-send "$@"
        fi
    fi
}

# Configuration
if [ ! -f "$HOME/.config/wallpaper-picker/config" ]; then
    _wwp_notify_send --urgency=critical "Wallpaper Picker Error" "Unable to load config file. Please see the README.md file for instructions"
    exit 1
fi

source "$HOME/.config/wallpaper-picker/config"

# Create cache directory if it doesn't exist
mkdir -p "$CACHE_DIR"


set_wallpaper() {
    [[ -z "$1" ]] && return 1

    if _wwp_has swaybg; then
        pkill -x swaybg 2>/dev/null || true
        swaybg --image "$1" --mode fill &
    elif _wwp_has swaymsg; then
        swaymsg output "*" bg "$1" fill
    else
        /home/blackgaze/Scripts/hyprWallpaper.sh "$1" &
    fi
}

# Function to generate thumbnail
generate_thumbnail() {
    local input="$1"
    local output="$2"
    magick "$input" -thumbnail "${THUMBNAIL_WIDTH}x${THUMBNAIL_HEIGHT}^" -gravity center -extent "${THUMBNAIL_WIDTH}x${THUMBNAIL_HEIGHT}" "$output"
}

# Create shuffle icon thumbnail on the fly
SHUFFLE_ICON="$CACHE_DIR/shuffle_thumbnail.png"
# Create a properly sized shuffle icon thumbnail
magick -size "${THUMBNAIL_WIDTH}x${THUMBNAIL_HEIGHT}" xc:#1e1e2e \
    \( "$INSTALL_DIR/assets/shuffle.png" -resize "80x80" \) \
    -gravity center -composite "$SHUFFLE_ICON"

# Generate thumbnails and create menu items
generate_menu() {
    # Add random/shuffle option with a name that sorts first (using ! prefix)
    echo -en "img:$SHUFFLE_ICON\x00info:!Random Wallpaper\x1fRANDOM\n"

    # Then add all wallpapers
    for img in "$WALLPAPER_DIR"/*.{jpg,jpeg,png}; do
        # Skip if no matches found
        [[ -f "$img" ]] || continue

        # Generate thumbnail filename
        thumbnail="$CACHE_DIR/$(basename "${img%.*}").png"

        # Generate thumbnail if it doesn't exist or is older than source
        if [[ ! -f "$thumbnail" ]] || [[ "$img" -nt "$thumbnail" ]]; then
            generate_thumbnail "$img" "$thumbnail"
        fi

        # Output menu item (filename and path)
        echo -en "img:$thumbnail\x00info:$(basename "$img")\x1f$img\n"
    done
}

# Use wofi to display grid of wallpapers - IMPORTANT: added --sort-order=default
selected=$(generate_menu | wofi --show dmenu \
    --cache-file /dev/null \
    --define "image-size=${THUMBNAIL_WIDTH}x${THUMBNAIL_HEIGHT}" \
    --columns 3 \
    --allow-images \
    --insensitive \
    --sort-order=default \
    --prompt "Select Wallpaper" \
    --conf "${INSTALL_DIR}/wofi/wallpaper.conf" \
  )

# Set wallpaper if one was selected
if [ -n "$selected" ]; then
    # Remove the img: prefix to get the cached thumbnail path
    thumbnail_path="${selected#img:}"

    # Check if random wallpaper was selected
    if [[ "$thumbnail_path" == "$SHUFFLE_ICON" ]]; then
        # Select a random wallpaper from the directory
        original_path=$(find "$WALLPAPER_DIR" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" \) | shuf -n 1)
    else
        # Get the original filename from the thumbnail path
        original_filename=$(basename "${thumbnail_path%.*}")

        # Find the corresponding original file in the wallpaper directory
        original_path=$(find "$WALLPAPER_DIR" -type f -name "${original_filename}.*" | head -n1)
    fi

    # Ensure a valid wallpaper was found before proceeding
    if [ -n "$original_path" ]; then
        # Set wallpaper using swww with the original file
        set_wallpaper "$original_path"

        # Save the selection for persistence
        echo "$original_path" > "$HOME/.cache/current_wallpaper"

        # Optional: Notify user
        _wwp_notify_send --urgency=normal "Wallpaper" "Wallpaper has been updated" -i "$original_path"
    else
        _wwp_notify_send --urgency=critical "Wallpaper Error" "Could not find the original wallpaper file."
    fi
fi

# Set an exit code so the process isn't running in the background
exit 0
