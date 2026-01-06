# Variable global para guardar la última imagen usada
set -g LAST_FASTFETCH_IMAGE ""
set -g LAST_COMMAND_WAS_FASTFETCH 0
set -g USER_STARTED_TYPING 0

function fastfetch
    # --- Cargar imágenes correctamente en fish ---
    set IMAGES /home/axel/Pictures/terminal-icons/*.jpg \
               /home/axel/Pictures/terminal-icons/*.jpeg \
               /home/axel/Pictures/terminal-icons/*.png \
               /home/axel/Pictures/terminal-icons/*.gif
    set IMAGES (string match -r '.+' $IMAGES)
    if test (count $IMAGES) -eq 0
        echo "images not found in '/Pictures/terminal-icons/'"
        return 1
    end
    
    # Si se proporciona una imagen como argumento, usarla
    if test -n "$argv[1]" -a -f "$argv[1]"
        set IMAGE "$argv[1]"
        set argv $argv[2..-1]  # Remover el primer argumento
    # Si NO hay imagen como argumento pero hay una guardada, elegir nueva aleatoriamente
    # (esto permite que cada ejecución manual tenga imagen diferente)
    else if test -n "$LAST_FASTFETCH_IMAGE" -a -f "$LAST_FASTFETCH_IMAGE"
        # Si hay una imagen previa guardada, usarla solo si viene del redimensionamiento
        # Para identificar esto, verificamos si $argv está vacío
        set IMAGE "$LAST_FASTFETCH_IMAGE"
    else
        # Elegir imagen aleatoria
        set IMAGE (printf "%s\n" $IMAGES | shuf -n1)
    end
    
    # Guardar la imagen actual para futuros usos
    set -g LAST_FASTFETCH_IMAGE "$IMAGE"
    set -g LAST_COMMAND_WAS_FASTFETCH 1
    
    set EXTENSION (string match -r '\.[^.]+$' "$IMAGE" | string sub -s 2)
    set TERM_COLS (tput cols)
    
    # --- Limpieza correcta y posicionar cursor al inicio ---
    printf "\033[2K\r"
    clear
    # Mover cursor a la primera línea
    printf "\033[H"
    
    # --- Determinar umbral para cambiar layout ---
    set MIN_WIDTH_SIDE_BY_SIDE 70
    set TERM_LINES (tput lines)
    
    # --- Configurar tamaños según ancho de terminal ---
    if test $TERM_COLS -lt $MIN_WIDTH_SIDE_BY_SIDE
        # Terminal pequeña: solo imagen a pantalla completa (con padding adaptativo)
        # Calcular aspect ratio multiplicado por 100 para comparaciones enteras
        set ASPECT_RATIO_X100 (math "floor(($TERM_LINES / $TERM_COLS) * 100)")
        
        # Si la terminal es más alta que ancha (cuadrada o vertical)
        if test $ASPECT_RATIO_X100 -gt 120
            # Terminal vertical/cuadrada: más padding horizontal, menos vertical
            set HORIZONTAL_PADDING (math "floor($TERM_COLS * 0.15) + 1")
            set VERTICAL_PADDING 2
        else if test $ASPECT_RATIO_X100 -gt 80
            # Terminal casi cuadrada: padding balanceado
            set HORIZONTAL_PADDING (math "floor($TERM_COLS * 0.10) + 1")
            set VERTICAL_PADDING 3
        else
            # Terminal horizontal: padding normal
            set HORIZONTAL_PADDING 3
            set VERTICAL_PADDING (math "floor($TERM_LINES * 0.10)")
        end
        
        set LOGO_WIDTH (math "$TERM_COLS - ($HORIZONTAL_PADDING * 2)")
        set LOGO_HEIGHT (math "$TERM_LINES - ($VERTICAL_PADDING * 2)")
        set LAYOUT_TYPE fullscreen
    else if test $TERM_COLS -lt 100
        # Terminal mediana: lado a lado con imagen pequeña
        set LOGO_WIDTH 24
        set LOGO_HEIGHT 14
        set LAYOUT_TYPE side
    else if test $TERM_COLS -lt 120
        # Terminal grande: lado a lado con imagen mediana
        set LOGO_WIDTH 28
        set LOGO_HEIGHT 15
        set LAYOUT_TYPE side
    else
        # Terminal muy grande: lado a lado con imagen grande
        set LOGO_WIDTH 32
        set LOGO_HEIGHT 17
        set LAYOUT_TYPE side
    end
    
    set CONFIG_PATH ~/.config/fastfetch/config.jsonc
    
    # --- Ejecutar fastfetch con configuración según tipo de imagen y layout ---
    if test "$LAYOUT_TYPE" = "fullscreen"
        # Terminal pequeña: solo mostrar imagen centrada ocupando casi toda la pantalla
        
        # Mover cursor a la posición correcta verticalmente
        printf "\033[%dB" $VERTICAL_PADDING
        
        # Agregar espacios para centrar horizontalmente usando el padding calculado
        printf "%*s" $HORIZONTAL_PADDING ""
        
        if test "$EXTENSION" = "gif"
            kitty +kitten icat --place {$LOGO_WIDTH}x{$LOGO_HEIGHT}@0x0 --transfer-mode file "$IMAGE" 2>/dev/null
        else
            kitty +kitten icat --place {$LOGO_WIDTH}x{$LOGO_HEIGHT}@0x0 --transfer-mode file "$IMAGE"
        end
        
        # Mover el cursor después de la imagen para el prompt
        printf "\033[%dB\n" (math "$LOGO_HEIGHT + 1")
    else
        # Layout horizontal: imagen al lado del texto
        if test "$EXTENSION" = "gif"
            command ~/fastfetch-gif-support/build/fastfetch \
                --config $CONFIG_PATH \
                --logo "$IMAGE" \
                --logo-type kitty-direct \
                --logo-animate \
                --logo-width $LOGO_WIDTH \
                --logo-height $LOGO_HEIGHT \
                --logo-padding-top 1 \
                --logo-padding-right 1 \
                $argv 2>/dev/null
        else
            command /usr/bin/fastfetch \
                --config $CONFIG_PATH \
                --logo "$IMAGE" \
                --logo-width $LOGO_WIDTH \
                --logo-height $LOGO_HEIGHT \
                --logo-padding-top 1 \
                --logo-padding-right 1 \
                $argv
        end
    end
    
    # --- Sin separación extra después del fastfetch ---
end

# Función que detecta cuando se redimensiona la terminal
function __fastfetch_on_resize --on-signal WINCH
    # Solo re-ejecutar si el último comando fue fastfetch Y el usuario no ha comenzado a escribir
    if test $LAST_COMMAND_WAS_FASTFETCH -eq 1 -a $USER_STARTED_TYPING -eq 0
        # Limpiar la terminal completamente para mantener el efecto visual
        clear
        printf "\033[2J\033[H"  # Limpieza más agresiva
        # Pequeño delay para esperar que termine el redimensionamiento
        sleep 0.1
        fastfetch "$LAST_FASTFETCH_IMAGE"
    end
end

# Función que se ejecuta cuando el usuario presiona cualquier tecla
function __fastfetch_clear_on_keypress
    if test $LAST_COMMAND_WAS_FASTFETCH -eq 1 -a $USER_STARTED_TYPING -eq 0
        set -g USER_STARTED_TYPING 1
        clear
        commandline -f repaint
    end
end

# Bind para detectar cuando se presiona cualquier tecla (letras, números, símbolos)
bind \e __fastfetch_clear_on_keypress  # Escape
bind \n __fastfetch_clear_on_keypress  # Enter
for char in (string split '' 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789 !@#$%^&*()_+-=[]{}|;:,.<>?/~`')
    bind $char "__fastfetch_clear_on_keypress; commandline -i '$char'"
end

# Hook que detecta cuando se ejecuta un comando
function __fastfetch_on_command --on-event fish_preexec
    # Si el comando no es fastfetch, desactivar completamente el sistema
    if not string match -q "fastfetch*" -- $argv[1]
        set -g LAST_COMMAND_WAS_FASTFETCH 0
        set -g USER_STARTED_TYPING 0
    else
        # Si ejecuta fastfetch de nuevo, resetear el flag de escritura
        set -g USER_STARTED_TYPING 0
    end
end
