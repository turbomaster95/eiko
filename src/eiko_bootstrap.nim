import std/[os, strutils, parseopt]
import cli, bootstrap

proc main() =
  if paramCount() < 1:
    echo "Usage: eiko-bootstrap [fix|syncnew]"
    quit(1)
  
  let command = paramStr(1)
  
  let appDir = getAppDir()
  let srcDir = appDir / "src"
  let manifest = srcDir / "api_manifest.nim"

  case command
  of "fix":
    let bs = newBootstrap()
    if checkApiConsistency(bs, manifest, srcDir):
      echo "[SUCCESS] API consistency check passed."
    else:
      echo "[ERROR] API consistency check failed."
      quit(1)
  of "syncnew":
    let bs = newBootstrap()
    if not dirExists("build/self"):
      createDir("build/self")
    
    if compileSelf(bs, srcDir, "build/self/eiko.new.exe"):
      echo "[SUCCESS] New binary compiled to build/self/eiko.new.exe"
    else:
      echo "[ERROR] Compilation failed"
      quit(1)
  else:
    echo "Error: Unknown command '", command, "'. Use 'fix' or 'syncnew'."
    quit(1)

when isMainModule:
  main()