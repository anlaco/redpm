# redpm - Red Package Manager

A simple package manager for Red language. Like npm or pip, but for Red.

## Installation

```bash
# Clone the repo
git clone https://github.com/ANLACO/redpm.git

# Compile
cd redpm
./redc -r -o redpm redpm.red

# Optional: Add to PATH
sudo cp redpm /usr/local/bin/
```

## Quick Start

```bash
# In your project directory
redpm init              # Create deps.red
# Edit deps.red to add dependencies
redpm install           # Install all dependencies
```

## Usage

### Initialize a project

```bash
redpm init
```

Creates a `deps.red` file in your project.

### Define dependencies

Edit `deps.red`:

```red
[
    Red-Serial "https://github.com/ANLACO/Red-Serial"
    Red-JSON   "https://github.com/user/Red-JSON"
]
```

### Install dependencies

```bash
redpm install
```

Downloads all dependencies into `deps/` folder.

### Update dependencies

```bash
redpm update
```

### List dependencies

```bash
redpm list
```

Shows all dependencies and their installation status:
```
Dependencies:

  ● Red-Serial (https://github.com/ANLACO/Red-Serial)
  ○ Red-JSON (not installed)
```

### Remove a package

```bash
redpm remove Red-JSON
```

## Project Structure

After `redpm install`, your project looks like:

```
my-project/
├── deps.red           # Dependencies list
├── deps/                 # Installed packages
│   ├── Red-Serial/
│   │   ├── Red-Serial.red
│   │   └── system/
│   └── Red-JSON/
└── src/
    └── main.red
```

## Using installed packages

In your Red code:

```red
Red []

#include %deps/Red-Serial/Red-Serial.red

port: open-serial "/dev/ttyUSB0"
; ...
```

## Commands

| Command | Description |
|---------|-------------|
| `init` | Create a new deps.red file |
| `install` | Install all dependencies from deps.red |
| `update` | Update all installed dependencies |
| `remove <pkg>` | Remove a specific package |
| `list` | List all dependencies and status |
| `help` | Show help message |

## Requirements

- Red compiler (redc)
- Git

## License

BSD-3-Clause License

## Author

ANLACO
