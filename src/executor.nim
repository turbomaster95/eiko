import std/[os, osproc, strutils, terminal]
import build_graph, help

type
  Executor* = object

proc newExecutor*(): Executor =
  Executor()

proc ensureDirExists(dir: string) =
  if not dirExists(dir):
    createDir(dir)

proc compileSource*(executor: Executor, source: SourceFile, target: Target, objPath: string) =
  ensureDirExists(parentDir(objPath))
  
  if target.compiler == "":
    displayError("No compiler specified for target '" & target.name & "'.")
    stdout.styledWriteLine(fgCyan, "Hint: ", fgDefault, "Add 'compiler gcc' to your Eikofile.")
    quit(1)
  
  var cmd = target.compiler & " -c " & source.path & " -o " & objPath
  
  # Add includes
  for inc in target.includes:
    cmd.add(" -I" & inc)
    
  # Add defines
  for def in target.defines:
    cmd.add(" -D" & def)
    
  # Add flags
  for flag in target.flags:
    cmd.add(" " & flag)
  
  echo "[DEBUG] Executing: ", cmd
  let (output, exitCode) = execCmdEx(cmd)
  if exitCode != 0:
    echo "[ERROR] Compilation failed!"
    echo "--- STDOUT/STDERR ---"
    echo output
    echo "---------------------"
    quit(1)

proc linkObjects*(executor: Executor, target: Target, objPaths: seq[string], depPaths: seq[string], outputPath: string) =
  ensureDirExists(parentDir(outputPath))
  
  case target.kind:
  of tkStatic:
    var cmd = "ar rcs " & outputPath & " " & objPaths.join(" ")
    echo "Creating static library: ", outputPath
    let (output, exitCode) = execCmdEx(cmd)
    if exitCode != 0:
      echo "Static library creation failed: ", output
      quit(1)
  else:
    if target.compiler == "":
      displayError("No compiler specified for target '" & target.name & "'.")
      stdout.styledWriteLine(fgCyan, "Hint: ", fgDefault, "Add 'compiler gcc' to your Eikofile.")
      quit(1)

    var cmd = target.compiler
    for obj in objPaths:
      cmd.add(" " & obj)
    
    # Link dependencies
    for dep in depPaths:
      cmd.add(" " & dep)
      
    cmd.add(" -o " & outputPath)
    
    if target.kind == tkShared:
      cmd.add(" -shared")
    
    # Add link flags
    for flag in target.link_flags:
      cmd.add(" " & flag)
      
    # Add general flags (excluding includes/defines which are for compilation)
    for flag in target.flags:
      if not flag.startsWith("-I") and not flag.startsWith("-D"):
        cmd.add(" " & flag)
    
    echo "[DEBUG] Executing: ", cmd
    let (output, exitCode) = execCmdEx(cmd)
    if exitCode != 0:
      echo "[ERROR] Linking failed!"
      echo "--- STDOUT/STDERR ---"
      echo output
      echo "---------------------"
      quit(1)