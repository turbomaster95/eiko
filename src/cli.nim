import std/[os, strutils, times, sequtils, tables]
import build_graph, executor

type
  BuildSystem* = object
    project*: Project
    executor*: Executor
    builtTargets: seq[string] # Keep track of what's built in this session

proc getTargetByName(project: Project, name: string): ptr Target =
  for i in 0..<project.targets.len:
    if project.targets[i].name == name:
      return addr project.targets[i]
  return nil

proc buildTarget(buildSystem: var BuildSystem, target: var Target) =
  if target.name in buildSystem.builtTargets:
    return
    
  # First, build dependencies
  var depPaths: seq[string] = @[]
  for depName in target.depends_on:
    let depTarget = getTargetByName(buildSystem.project, depName)
    if depTarget != nil:
      buildTarget(buildSystem, depTarget[])
      depPaths.add(getOutputPath(depTarget[]))
    else:
      echo "[WARNING] Dependency not found: ", depName

  echo "[DEBUG] Building target: ", target.name
  var objPaths: seq[string] = @[]
  
  # Compile each source file
  for source in target.sources:
    let objPath = getObjPath(source.path)
    objPaths.add(objPath)
    
    if needsRebuild(source.path, objPath):
      compileSource(buildSystem.executor, source, target, objPath)
  
  # Link the target
  let outputPath = getOutputPath(target)
  var needsLink = false
  
  if target.kind == tkStatic:
    if not fileExists(outputPath):
      needsLink = true
    else:
      let libTime = getLastModificationTime(outputPath)
      for source in target.sources:
        if getLastModificationTime(source.path) > libTime:
          needsLink = true
          break
  else:
    if targetNeedsRebuild(target):
      needsLink = true
    else:
      # Also check if dependencies are newer than output
      let outputTime = if fileExists(outputPath): getLastModificationTime(outputPath) else: Time()
      for depPath in depPaths:
        if fileExists(depPath) and getLastModificationTime(depPath) > outputTime:
          needsLink = true
          break
  
  if needsLink:
    linkObjects(buildSystem.executor, target, objPaths, depPaths, outputPath)
    
  buildSystem.builtTargets.add(target.name)

proc build*(buildSystem: var BuildSystem) =
  echo "[DEBUG] Starting build process..."
  if not dirExists("build"):
    createDir("build")
  if not dirExists("build/obj"):
    createDir("build/obj")
  
  buildSystem.builtTargets = @[]
  # Use a copy of targets index because we are passing var
  for i in 0..<buildSystem.project.targets.len:
    buildTarget(buildSystem, buildSystem.project.targets[i])
  echo "[DEBUG] Build completed successfully."

proc clean*() =
  if dirExists("build"):
    removeDir("build")
    echo "Cleaned build directory"

proc graph*(buildSystem: BuildSystem) =
  echo "Project: ", buildSystem.project.name
  for target in buildSystem.project.targets:
    echo "Target: ", target.name, " (", target.kind, ")"
    if target.compiler != "": echo "  Compiler: ", target.compiler
    echo "  Sources: ", target.sources.mapIt(it.path).join(", ")
    if target.includes.len > 0: echo "  Includes: ", target.includes.join(", ")
    if target.defines.len > 0: echo "  Defines: ", target.defines.join(", ")
    if target.depends_on.len > 0: echo "  Depends: ", target.depends_on.join(", ")
    if target.flags.len > 0: echo "  Flags: ", target.flags.join(" ")
    if target.link_flags.len > 0: echo "  Link Flags: ", target.link_flags.join(" ")
    echo "  Output: ", getOutputPath(target)
    echo ""