import std/[os, strutils]
import cli, executor, bootstrap, help, eikofile_parser

proc main() =
  if paramCount() < 1:
    displayHelp()
    quit(0)
  
  let command = paramStr(1)
  
  case command
  of "build":
    if not fileExists("Eikofile"):
      displayError("Eikofile not found in current directory")
      quit(1)
    
    let project = parseEikofile("Eikofile")
    var buildSystem = BuildSystem(project: project, executor: newExecutor())
    build(buildSystem)
  of "clean":
    clean()
  of "graph":
    if not fileExists("Eikofile"):
      displayError("Eikofile not found in current directory")
      quit(1)
    
    let project = parseEikofile("Eikofile")
    let buildSystem = BuildSystem(project: project, executor: newExecutor())
    graph(buildSystem)
  of "sync":
    let bs = newBootstrap()
    let appDir = getAppDir()
    let srcDir = appDir / "src"
    let manifest = srcDir / "api_manifest.nim"
    
    if not dirExists(srcDir):
      displayError("Eiko source directory not found at " & srcDir)
      quit(1)

    # Pre-build check: Has the source changed since last sync?
    let homeDir = getHomeDir()
    let hashPath = homeDir / ".eiko" / "bin" / ".sync_hash"
    if fileExists(hashPath):
      let lastSrcHash = readFile(hashPath).strip()
      let currentSrcHash = getSrcHash(srcDir)
      if lastSrcHash != "" and lastSrcHash == currentSrcHash:
        echo "[SUCCESS] Eiko is already up to date (source hash matches)."
        return

    if not checkApiConsistency(bs, manifest, srcDir):
      displayError("API consistency check failed. Fix the manifest or sources before syncing.")
      quit(1)
    
    if not dirExists("build/self"):
      createDir("build/self")
    
    let newBinaryPath = "build/self/eiko.new.exe"
    if compileSelf(bs, srcDir, newBinaryPath):
      if syncBinary(bs, newBinaryPath, srcDir):
        echo "[SUCCESS] Eiko synchronized and updated in ~/.eiko/bin/eiko"
      else:
        displayError("Failed to install the new binary.")
        quit(1)
    else:
      displayError("Self-compilation failed.")
      quit(1)
  of "help", "--help", "-h":
    displayHelp()
    quit(0)
  else:
    displayError("Unknown command '" & command & "'.")
    quit(1)

when isMainModule:
  main()