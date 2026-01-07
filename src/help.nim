import std/terminal

proc displayHelp*() =
  let
    logoColor = fgCyan
    headerColor = fgYellow
    cmdColor = fgGreen
    descColor = fgDefault
    dimColor = fgWhite # For subtle hints

  stdout.styledWriteLine(logoColor, styleBright, "  ███████╗██╗██╗  ██╗ ██████╗ ")
  stdout.styledWriteLine(logoColor, styleBright, "  ██╔════╝██║██║ ██╔╝██╔═══██╗")
  stdout.styledWriteLine(logoColor, styleBright, "  █████╗  ██║█████╔╝ ██║   ██║")
  stdout.styledWriteLine(logoColor, styleBright, "  ██╔══╝  ██║██╔═██╗ ██║   ██║")
  stdout.styledWriteLine(logoColor, styleBright, "  ███████╗██║██║  ██╗╚██████╔╝")
  stdout.styledWriteLine(logoColor, styleBright, "  ╚══════╝╚═╝╚═╝  ╚═╝ ╚═════╝ ")
  stdout.styledWriteLine(fgMagenta, "    The Minimalist Build System")
  echo ""

  stdout.styledWrite(headerColor, styleBright, "Usage: ")
  stdout.styledWriteLine(descColor, "eiko ", cmdColor, "[command] ", dimColor, "[options]")
  echo ""

  stdout.styledWriteLine(headerColor, styleBright, "Commands:")
  
  stdout.styledWrite("  ", cmdColor, styleBright, "build")
  stdout.styledWriteLine(descColor, "     Build the project (requires Eikofile)")
  
  stdout.styledWrite("  ", cmdColor, styleBright, "clean")
  stdout.styledWriteLine(descColor, "     Remove build artifacts")
  
  stdout.styledWrite("  ", cmdColor, styleBright, "sync")
  stdout.styledWriteLine(descColor, "      Synchronize and update eiko binary from source")
  
  stdout.styledWrite("  ", cmdColor, styleBright, "graph")
  stdout.styledWriteLine(descColor, "     Display project structure and target graph")
  
  stdout.styledWrite("  ", cmdColor, styleBright, "help")
  stdout.styledWriteLine(descColor, "      Display this help message")
  
  echo ""
  stdout.styledWriteLine(dimColor, "Use \"eiko [command] --help\" for more information about a command.")

proc displayError*(msg: string) =
  stdout.styledWriteLine(fgRed, styleBright, "Error: ", fgDefault, msg)
  stdout.styledWriteLine(fgCyan, "Run 'eiko help' for usage information.")
