cat > ~/.local/bin/myfetch << 'EOF'
#!/bin/zsh
# myfetch - Script para mostrar fastfetch con imagen/ascii aleatoria
#
# INSTALACION:
#   1. Copia este archivo a ~/.local/bin/myfetch
#   2. Dale permisos de ejecucion: chmod +x ~/.local/bin/myfetch
#   3. Asegurate de que ~/.local/bin este en tu PATH agregando esto a ~/.zshrc:
#        export PATH="$HOME/.local/bin:$PATH"
#
# USO EN .zshrc:
#   Para ejecutar al abrir cualquier terminal, agrega al INICIO de ~/.zshrc
#   (antes del bloque de p10k instant prompt):
#        clear
#        myfetch
#
#   Para usarlo como comando reemplazando fastfetch, agrega en ~/.zshrc:
#        alias fastfetch='clear; myfetch'
#
# CARPETAS REQUERIDAS:
#   - Imagenes (para kitty/wezterm):  ~/Pictures/ff-term/
#     Formatos soportados: gif, png, jpg, jpeg, webp, bmp, tiff
#   - ASCII art (para ghostty):       ~/Pictures/ff-ascii/
#     Formato: archivos .txt con arte ASCII
#
# DEPENDENCIAS:
#   - fastfetch (para imagenes estaticas):  /usr/bin/fastfetch
#   - fastfetch con gif support (para gif): ~/fastfetch-gif-support/build/fastfetch
#   - kitty (para protocolo de imagenes):   pacman -S kitty
#
# CONFIGURACION DE FASTFETCH:
#   El config se lee desde: ~/.config/fastfetch/config.jsonc

IMAGE=$(find ~/Pictures/ff-term/ -type f \( -iname "*.gif" -o -iname "*.png" -o -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.webp" -o -iname "*.bmp" -o -iname "*.tiff" \) | shuf -n1)
EXT="${IMAGE:e:l}"
LOGO_HEIGHT=11

if [ "$TERM_PROGRAM" = "ghostty" ]; then
    # Ghostty: usa ASCII art aleatorio desde ~/Pictures/ff-ascii/
    ASCII=$(find ~/Pictures/ff-ascii/ -type f -iname "*.txt" | shuf -n1)
    /usr/bin/fastfetch --pipe false --config ~/.config/fastfetch/config.jsonc --logo "$ASCII" --logo-type file
elif [ "$EXT" = "gif" ]; then
    # Kitty/WezTerm: usa gif animado
    ~/fastfetch-gif-support/build/fastfetch --pipe false --config ~/.config/fastfetch/config.jsonc --logo "$IMAGE" --logo-type kitty-icat --logo-animate --logo-width 30 --logo-height $LOGO_HEIGHT --logo-padding-right 2
else
    # Kitty/WezTerm: usa imagen estatica
    /usr/bin/fastfetch --pipe false --config ~/.config/fastfetch/config.jsonc --logo "$IMAGE" --logo-type kitty --logo-width 30 --logo-height $LOGO_HEIGHT --logo-padding-right 2
fi
EOF
chmod +x ~/.local/bin/myfetch
