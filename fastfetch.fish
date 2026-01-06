# ~/.config/fish/functions/fastfetch.fish
# Versión ajustada: padding-top reducido y resize handler restaurado (con debounce).
# Variables globales
set -g LAST_FASTFETCH_IMAGE ""
set -g LAST_COMMAND_WAS_FASTFETCH 0
set -g USER_STARTED_TYPING 0

function fastfetch
    # --- Cargar imágenes robusto ---
    set -l IMAGE_DIR $HOME/Pictures/terminal-icons
    set -l IMAGES
    for ext in jpg jpeg png gif
        for f in $IMAGE_DIR/*.$ext
            if test -f "$f"
                set -a IMAGES "$f"
            end
        end
    end

    if test (count $IMAGES) -eq 0
        echo "No se encontraron imágenes en $IMAGE_DIR/"
        return 1
    end

    # Selección de imagen (argumento > guardada > aleatoria)
    if test -n "$argv[1]" -a -f "$argv[1]"
        set IMAGE "$argv[1]"
        set argv $argv[2..-1]
    else if test -n "$LAST_FASTFETCH_IMAGE" -a -f "$LAST_FASTFETCH_IMAGE"
        set IMAGE "$LAST_FASTFETCH_IMAGE"
    else
        set IMAGE (printf "%s\n" $IMAGES | shuf -n1)
    end

    set -g LAST_FASTFETCH_IMAGE "$IMAGE"
    set -g LAST_COMMAND_WAS_FASTFETCH 1

    set EXTENSION (string match -r '\.[^.]+$' "$IMAGE" | string sub -s 2)
    set TERM_COLS (tput cols)
    set TERM_LINES (tput lines)

    # --- Limpieza ---
    printf "\033[2J\033[H"

    # --- Dimensiones de la imagen (pixels) ---
    set IMAGE_INFO (identify -format "%w %h" "$IMAGE" 2>/dev/null)
    if test -n "$IMAGE_INFO"
        set IMAGE_WIDTH (echo $IMAGE_INFO | cut -d' ' -f1)
        set IMAGE_HEIGHT (echo $IMAGE_INFO | cut -d' ' -f2)
        if test $IMAGE_HEIGHT -gt $IMAGE_WIDTH
            set IMAGE_IS_TALL 1
            set IMAGE_IS_SQUARE 0
        else if test $IMAGE_HEIGHT -eq $IMAGE_WIDTH
            set IMAGE_IS_TALL 0
            set IMAGE_IS_SQUARE 1
        else
            set IMAGE_IS_TALL 0
            set IMAGE_IS_SQUARE 0
        end
    else
        set IMAGE_IS_TALL 0
        set IMAGE_IS_SQUARE 0
    end

    # --- Layout / tamaños base ---
    set MIN_WIDTH_SIDE_BY_SIDE 70
    set CONFIG_PATH $HOME/.config/fastfetch/config.jsonc

    # Ajusta esto si tu bloque OS->Swap tiene más/menos líneas (altura visual deseada)
    set -l FASTFETCH_LINES 13

    # Número de filas antes del bloque OS (ajusta si tu title / logo ocupan más filas)
    # Valor por defecto 2, pero reducimos el padding-top final para evitar el "exagerado"
    set -l FASTFETCH_TOP_OFFSET 2

    if test $TERM_COLS -lt $MIN_WIDTH_SIDE_BY_SIDE
        # MODO PANTALLA COMPLETA: centrado grande
        set LOGO_WIDTH (math "floor($TERM_COLS * 0.85)")
        set LOGO_HEIGHT (math "floor($TERM_LINES * 0.85)")

        if test $IMAGE_IS_TALL -eq 1
            set VERTICAL_PADDING (math "max(0, floor(($TERM_LINES - $LOGO_HEIGHT) / 2) - 2)")
        else if test $IMAGE_IS_SQUARE -eq 1
            set VERTICAL_PADDING (math "max(0, floor(($TERM_LINES - $LOGO_HEIGHT) / 2))")
        else
            set VERTICAL_PADDING (math "max(1, floor($TERM_LINES * 0.08))")
        end

        set HORIZONTAL_PADDING (math "max(1, floor(($TERM_COLS - $LOGO_WIDTH) / 2))")
        test $VERTICAL_PADDING -gt 0; and printf "\033[%dB" $VERTICAL_PADDING
        printf "%*s" $HORIZONTAL_PADDING ""

        if test "$EXTENSION" = "gif"
            kitty +kitten icat --place {$LOGO_WIDTH}x{$LOGO_HEIGHT}@0x0 --transfer-mode file "$IMAGE" 2>/dev/null
        else
            kitty +kitten icat --place {$LOGO_WIDTH}x{$LOGO_HEIGHT}@0x0 --transfer-mode file "$IMAGE" 2>/dev/null
        end

        printf "\033[%dB\n" (math "$LOGO_HEIGHT - $VERTICAL_PADDING + 1")

    else
        # MODO LADO A LADO: queremos que la imagen coincida con el bloque OS->Swap

        # ALTURA objetivo en filas = FASTFETCH_LINES
        set LOGO_HEIGHT $FASTFETCH_LINES

        # Factor aproximado de ancho por fila en columnas (ajusta si tu fuente es diferente)
        set -l CELL_ASPECT 2.0

        # Estimación inicial de ancho en columnas
        set -l est_width (math "floor($LOGO_HEIGHT * $CELL_ASPECT)")

        # Límites razonables para ancho (evita tamaños ridículos)
        set -l MIN_LOGO_W 20
        set -l MAX_LOGO_W (math "max(40, floor($TERM_COLS * 0.35))")

        # Clamp del ancho estimado
        set LOGO_WIDTH (math "floor(min(max($est_width, $MIN_LOGO_W), $MAX_LOGO_W))")

        # Si la imagen es muy ancha, permitir un poco más (hasta 1.5x)
        if test $IMAGE_IS_SQUARE -eq 0 -a $IMAGE_IS_TALL -eq 0
            set -l img_ratio (math "scale=2; $IMAGE_WIDTH / $IMAGE_HEIGHT")
            if test (math "$img_ratio > 1.5") -eq 1
                set -l extra (math "floor($LOGO_WIDTH * 0.25)")
                set LOGO_WIDTH (math "min($LOGO_WIDTH + $extra, $MAX_LOGO_W)")
            end
        end

        # --- Ajuste de logo-padding-top reducido ---
        # Antes usábamos FASTFETCH_TOP_OFFSET directamente; eso resultaba ligeramente exagerado.
        # Aquí reducimos 1 fila para suavizar. Si hace falta menos, pon FASTFETCH_TOP_ADJUST a 0.
        set -l FASTFETCH_TOP_ADJUST 1
        set LOGO_PADDING_TOP (math "max(0, $FASTFETCH_TOP_OFFSET - $FASTFETCH_TOP_ADJUST)")

        # Si la imagen es muy alta y queremos que empiece desde la fila del usuario/title,
        # reducimos padding a 0 (mantener el top pegado)
        if test $IMAGE_IS_TALL -eq 1
            set LOGO_PADDING_TOP 0
        end

        # Ejecutar fastfetch pidiendo el logo con la altura exacta del bloque
        if test "$EXTENSION" = "gif"
            command ~/fastfetch-gif-support/build/fastfetch \
                --config $CONFIG_PATH \
                --logo "$IMAGE" \
                --logo-type kitty-direct \
                --logo-animate \
                --logo-width $LOGO_WIDTH \
                --logo-height $LOGO_HEIGHT \
                --logo-padding-right 2 \
                --logo-padding-top $LOGO_PADDING_TOP \
                $argv 2>/dev/null
        else
            command /usr/bin/fastfetch \
                --config $CONFIG_PATH \
                --logo "$IMAGE" \
                --logo-width $LOGO_WIDTH \
                --logo-height $LOGO_HEIGHT \
                --logo-padding-right 2 \
                --logo-padding-top $LOGO_PADDING_TOP \
                $argv 2>/dev/null
        end
    end
end

# Re-ejecutar en redimensionamiento (sin parpadeos, con debounce)
function __fastfetch_on_resize --on-signal WINCH
    # Solo re-ejecutar si el último comando fue fastfetch y el usuario no ha comenzado a escribir
    if test $LAST_COMMAND_WAS_FASTFETCH -eq 1 -a $USER_STARTED_TYPING -eq 0
        # Debounce corto para evitar múltiples redibujos rápidos
        sleep 0.08
        # Verificar todavía no comenzó a escribir y que haya una imagen guardada
        if test $USER_STARTED_TYPING -eq 0
            # Llamar con la última imagen conocida para forzar mismo logo
            fastfetch "$LAST_FASTFETCH_IMAGE"
        end
    end
end

# Limpiar al escribir (mantener comportamiento)
function __fastfetch_clear_on_keypress
    if test $LAST_COMMAND_WAS_FASTFETCH -eq 1 -a $USER_STARTED_TYPING -eq 0
        set -g USER_STARTED_TYPING 1
        printf "\033[2J\033[H"
        commandline -f repaint
    end
end

# Binds optimizados (sin -k)
bind \r __fastfetch_clear_on_keypress  # Enter
bind \e __fastfetch_clear_on_keypress  # Escape
bind \b __fastfetch_clear_on_keypress  # Backspace
bind \x7f __fastfetch_clear_on_keypress  # Delete

for char in (string split '' 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789')
    bind $char "begin; __fastfetch_clear_on_keypress; commandline -i '$char'; end"
end

# Hook que detecta cuando se ejecuta un comando
function __fastfetch_on_command --on-event fish_preexec
    if not string match -q "fastfetch*" -- $argv[1]
        set -g LAST_COMMAND_WAS_FASTFETCH 0
        set -g USER_STARTED_TYPING 0
    else
        set -g USER_STARTED_TYPING 0
    end
end
