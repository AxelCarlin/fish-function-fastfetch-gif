# Fastfetch GIF Support - Fish Function

A sophisticated Fish shell function that brings dynamic image and GIF support to Fastfetch on Kitty terminal and compatible terminals.

## 🌟 Features

- **GIF Animation Support**: Display animated GIFs in your terminal using Kitty's graphics protocol
- **Random Image Selection**: Automatically picks a random image from your collection on each execution
- **Adaptive Layout**: Automatically adjusts layout based on terminal dimensions
  - **Fullscreen mode**: For narrow terminals (<70 columns) - displays centered image only
  - **Side-by-side mode**: For wider terminals - image alongside system information
- **Smart Aspect Ratio Handling**: Calculates optimal padding based on terminal proportions
- **Auto-resize**: Automatically re-renders when terminal is resized
- **Interactive Clearing**: Clears the display when you start typing

## 📋 Requirements

- [Fish Shell](https://fishshell.com/) 3.0+
- [Kitty Terminal](https://sw.kovidgoyal.net/kitty/) (primary support)
- [Fastfetch](https://github.com/fastfetch-cli/fastfetch) (standard version for static images)
- [Fastfetch GIF Support](https://github.com/Maybe4a6f7365/fastfetch-gif-support.git) (custom build for GIF animations)
- `shuf` utility (usually pre-installed on Linux systems)

## 🚀 Installation

### 1. Install Dependencies

```bash
# Install Fish shell (if not already installed)
# On Ubuntu/Debian: 
sudo apt install fish

# On Arch Linux:
sudo pacman -S fish

# Install Kitty terminal
# On Ubuntu/Debian:
sudo apt install kitty

# On Arch Linux: 
sudo pacman -S kitty
```

### 2. Install Standard Fastfetch

```bash
# On Ubuntu/Debian:
sudo apt install fastfetch

# On Arch Linux:
sudo pacman -S fastfetch
```

### 3. Install Fastfetch with GIF Support

```bash
# Clone the GIF support repository
git clone https://github.com/Maybe4a6f7365/fastfetch-gif-support.git ~/fastfetch-gif-support

# Build from source
cd ~/fastfetch-gif-support
mkdir build && cd build
cmake .. 
make

# The binary will be at ~/fastfetch-gif-support/build/fastfetch
```

### 4. Install the Fish Function

```bash
# Download the function
curl -o ~/.config/fish/functions/fastfetch.fish https://raw.githubusercontent.com/AxelCarlin/fish-function-fastfetch-gif/main/fastfetch.fish

# Or clone the repository
git clone https://github.com/AxelCarlin/fish-function-fastfetch-gif.git
cp fish-function-fastfetch-gif/fastfetch.fish ~/.config/fish/functions/
```

### 5. Prepare Your Image Directory

```bash
# Create directory for your images
mkdir -p ~/Pictures/terminal-icons

# Add your images (JPG, JPEG, PNG, GIF)
# The function will automatically detect and use them
```

**Important**: Edit line 8-11 in `fastfetch.fish` to match your image directory path if different from `~/Pictures/terminal-icons/`

## 🎮 Usage

### Basic Usage

Simply run the command: 

```fish
fastfetch
```

The function will:
1. Randomly select an image from your configured directory
2. Detect your terminal size
3. Choose the optimal layout (fullscreen or side-by-side)
4. Display the image with system information (if space allows)

### Using a Specific Image

```fish
fastfetch /path/to/your/image.png
```

or

```fish
fastfetch ~/Pictures/my-favorite.gif
```

### Passing Additional Arguments

```fish
fastfetch --config /path/to/custom/config.jsonc
```

## ⚙️ How It Works

### Image Type Detection

The function automatically detects the image format: 

- **GIF files**: Uses the custom `fastfetch-gif-support` build to enable animation
- **Static images** (JPG, PNG): Uses the standard fastfetch installation

### Layout Logic

The function calculates terminal dimensions and chooses a layout:

#### Fullscreen Mode (< 70 columns)
- Displays only the image, centered and maximized
- Calculates adaptive padding based on aspect ratio: 
  - **Vertical terminals** (height/width > 1.2): More horizontal padding, less vertical
  - **Square terminals** (ratio 0.8-1.2): Balanced padding
  - **Horizontal terminals** (ratio < 0.8): More vertical padding

#### Side-by-side Mode (≥ 70 columns)
- **70-100 columns**: Small image (24×14)
- **100-120 columns**: Medium image (28×15)
- **120+ columns**: Large image (32×17)
- System information displayed alongside the image

### Remote Repository Integration

The function leverages the [fastfetch-gif-support](https://github.com/Maybe4a6f7365/fastfetch-gif-support.git) repository, which is a modified version of fastfetch that adds: 

- Native GIF animation support using Kitty's graphics protocol
- `--logo-animate` flag for GIF rendering
- `--logo-type kitty-direct` for direct Kitty protocol communication

This remote repository is essential for GIF functionality, as the standard fastfetch only supports static images.

### Interactive Features

#### Auto-resize on Window Change
When you resize the terminal window: 
- The WINCH signal is captured
- Display is automatically cleared and re-rendered
- Same image is maintained across resizes

#### Smart Clear on Typing
When you start typing:
- Display is automatically cleared
- Command line is ready for input
- Prevents visual overlap with commands

## 🎨 Configuration

### Customizing Image Directory

Edit lines 8-11 in `fastfetch.fish`:

```fish
set IMAGES /your/custom/path/*.jpg \
           /your/custom/path/*.jpeg \
           /your/custom/path/*.png \
           /your/custom/path/*.gif
```

### Customizing Layout Thresholds

Edit line 47 to change when fullscreen mode activates:

```fish
set MIN_WIDTH_SIDE_BY_SIDE 70  # Change this value
```

### Customizing Fastfetch Configuration

The function uses `~/.config/fastfetch/config.jsonc` by default. Create your own: 

```bash
mkdir -p ~/.config/fastfetch
fastfetch --gen-config
```

Then edit `~/.config/fastfetch/config.jsonc` to customize the information displayed.

## 🔧 Compatible Terminals

### Full Support
- **Kitty** - Primary target, full GIF animation support

### Partial Support
Terminals with graphics protocol support may work with static images: 
- **WezTerm** - Supports Kitty graphics protocol
- **Konsole** - Limited support
- **iTerm2** - (macOS) Has its own graphics protocol

### Not Supported
- Standard terminals without graphics protocol (urxvt, xterm, alacritty, etc.)

## 📝 Technical Details

### Global Variables

```fish
LAST_FASTFETCH_IMAGE      # Stores the last used image path
LAST_COMMAND_WAS_FASTFETCH # Flag to track if fastfetch was the last command
USER_STARTED_TYPING        # Flag to track if user has started typing
```

### Event Hooks

- `--on-signal WINCH`: Handles terminal resize events
- `--on-event fish_preexec`: Tracks command execution
- Key bindings: Detects user input to trigger display clearing

### File Paths

- **GIF-enabled fastfetch**: `~/fastfetch-gif-support/build/fastfetch`
- **Standard fastfetch**: `/usr/bin/fastfetch`
- **Configuration**: `~/.config/fastfetch/config.jsonc`

## 🐛 Troubleshooting

### Images Not Found Error

```
images not found in '/Pictures/terminal-icons/'
```

**Solution**: Create the directory and add images, or update the path in the function.

### GIFs Not Animating

**Solution**: Ensure you've built and installed fastfetch-gif-support correctly: 

```bash
cd ~/fastfetch-gif-support/build
./fastfetch --version  # Should show version info
```

### Display Issues on Resize

**Solution**: Adjust the sleep value on line 147:

```fish
sleep 0.1  # Increase to 0.2 or 0.3 for slower systems
```

## 🤝 Contributing

Contributions are welcome! Feel free to:
- Report bugs
- Suggest new features
- Submit pull requests
- Share your custom configurations

## 📄 License

[Specify your license]

## 🙏 Credits

- [fastfetch-cli/fastfetch](https://github.com/fastfetch-cli/fastfetch) - Original fastfetch project
- [Maybe4a6f7365/fastfetch-gif-support](https://github.com/Maybe4a6f7365/fastfetch-gif-support) - GIF animation support
- [Kitty Terminal](https://sw.kovidgoyal.net/kitty/) - Graphics protocol implementation

## 📸 Screenshots

_Add your screenshots here to showcase the function in action!_

---

**Made with ❤️ for Fish shell and Kitty terminal users**