# Eiko Build System

Eiko is a minimal, hackable build system using KDL configuration files.

## Building Eiko

To build the main Eiko binary:
```
nim c -o:eiko.exe src\eiko.nim
```

To build the bootstrap binary:
```
nim c -o:eiko-bootstrap.exe src\eiko_bootstrap.nim
```

## Usage

### Main Commands
- `eiko build` - Build project according to `eiko.kdl`
- `eiko clean` - Remove all build artifacts in `build/`
- `eiko sync` - Atomically rebuilds Eiko itself from the editable source
- `eiko graph` - Prints the dependency graph for debugging

### Bootstrap Commands
- `eiko-bootstrap fix` - Checks API consistency
- `eiko-bootstrap syncnew` - Compiles a new Eiko binary to `build/self/eiko.new`

## Configuration

Create an `eiko.kdl` file in your project directory:

```
project "demo" {
  target "app" {
    kind "executable"
    sources "main.c" "util.c"
    compiler "gcc"
    flags "-O2" "-Wall"
  }
}
```

## Supported Target Kinds
- `executable` - Creates an executable
- `static` - Creates a static library
- `shared` - Creates a shared library

## Philosophy

- **Reproducible**: Identical inputs always produce identical outputs
- **Speedy**: Incremental builds with timestamp-based caching
- **Hackable**: Edit source in ~/.eiko and rebuild the system itself