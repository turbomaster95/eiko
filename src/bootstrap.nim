import std/[os, strutils, osproc, sha1, algorithm]

type
  Bootstrap* = object

proc newBootstrap*(): Bootstrap =
  Bootstrap()

proc checkApiConsistency*(bootstrap: Bootstrap, manifestPath: string, sourceDir: string): bool =
  echo "[DEBUG] Checking API consistency..."
  if not fileExists(manifestPath):
    echo "[ERROR] Manifest not found: ", manifestPath
    return false
  
  let manifestContent = readFile(manifestPath)
  var exportedInSrc: seq[string] = @[]
  
  for file in walkDirRec(sourceDir):
    if file.endsWith(".nim") and not file.endsWith("api_manifest.nim"):
      let content = readFile(file)
      # Very basic scanner for exported symbols
      for line in content.splitLines():
        let transition = line.strip()
        if transition.startsWith("proc ") or transition.startsWith("func ") or 
           transition.startsWith("template ") or transition.startsWith("iterator "):
          let parts = transition.split({' ', '(', ':', '*'})
          if parts.len > 1:
            let name = parts[1]
            if transition.contains(name & "*"):
              exportedInSrc.add(name)
  
  var missingInManifest: seq[string] = @[]
  for sym in exportedInSrc:
    if not manifestContent.contains(sym & "*"):
      missingInManifest.add(sym)
  
  if missingInManifest.len > 0:
    echo "[ERROR] Exported symbols missing from manifest:"
    for sym in missingInManifest:
      echo "  - ", sym
    return false
  
  echo "[DEBUG] API consistency check passed."
  return true

proc compileSelf*(bootstrap: Bootstrap, sourceDir: string, outputPath: string): bool =
  echo "[DEBUG] Compiling new Eiko binary..."
  let cmd = "nim c -d:release -o:" & quoteShell(outputPath) & " " & quoteShell(sourceDir / "eiko.nim")
  echo "[DEBUG] Executing: ", cmd
  let (output, exitCode) = execCmdEx(cmd)
  if exitCode != 0:
    echo "[ERROR] Self-compilation failed!"
    echo output
    return false
  
  echo "[DEBUG] Self-compilation successful: ", outputPath
  return true

proc getFileHash*(path: string): string =
  if not fileExists(path): return ""
  try:
    return $secureHashFile(path)
  except:
    return ""

proc getSrcHash*(sourceDir: string): string =
  var hashes: seq[string] = @[]
  for file in walkDirRec(sourceDir):
    if file.endsWith(".nim"):
      hashes.add(getFileHash(file))
  
  if hashes.len == 0: return ""
  # Sort to ensure determinism
  hashes.sort()
  return $secureHash(hashes.join(""))

proc syncBinary*(bootstrap: Bootstrap, newBinaryPath: string, sourceDir: string): bool =
  let homeDir = getHomeDir()
  let binDir = homeDir / ".eiko" / "bin"
  let targetPath = binDir / "eiko.exe"
  let oldPath = binDir / "eiko.old"
  let hashPath = binDir / ".sync_hash"
  
  if fileExists(targetPath):
    let oldHash = getFileHash(targetPath)
    let newHash = getFileHash(newBinaryPath)
    if oldHash != "" and oldHash == newHash:
      echo "[DEBUG] Binary is identical to installed version. Skipping update."
      return true

  try:
    if not dirExists(binDir):
      createDir(binDir)
    
    if fileExists(targetPath):
      if fileExists(oldPath):
        removeFile(oldPath)
      moveFile(targetPath, oldPath)
    
    copyFile(newBinaryPath, targetPath)
    
    # Save the source hash to allow skipping the build next time
    let srcHash = getSrcHash(sourceDir)
    if srcHash != "":
      writeFile(hashPath, srcHash)
    
    echo "[DEBUG] Successfully synced binary to ", targetPath
    return true
  except OSError as e:
    echo "[ERROR] Failed to sync binary: ", e.msg
    # Try to roll back if target was moved but new one failed
    if fileExists(oldPath) and not fileExists(targetPath):
      moveFile(oldPath, targetPath)
    return false