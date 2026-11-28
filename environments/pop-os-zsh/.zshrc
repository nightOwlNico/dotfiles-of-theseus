# Created by newuser for 5.8.1

eval "$(starship init zsh)"

alias windows='sudo efibootmgr -n 0000 && reboot'

# alias audio='pactl load-module module-loopback source=alsa_input.usb-HiFimeDIY_SA9227_USB_Audio-01.iec958-stereo source_dont_move=true sink_dont_move=false channels=2 latency_msec=20'
alias audio-status='wpctl status'
audio() {
    local source="alsa_input.usb-HiFimeDIY_SA9227_USB_Audio-01.iec958-stereo"

    if ! pactl list short sources | grep -qF "$source"; then
        echo "❌ S2 Digi source not detected."
        return 1
    fi

    if pactl list short modules | grep -q "module-loopback.*$source"; then
        echo "ℹ️ Loopback already active."
        return 0
    fi

    pactl load-module module-loopback \
        source="$source" \
        source_dont_move=true \
        sink_dont_move=false \
        channels=2 \
        latency_msec=20
}