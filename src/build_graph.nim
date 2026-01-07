import std/[os, times]

type
  TargetKind* = enum
    tkExecutable, tkStatic, tkShared

  SourceFile* = object
    path*: string

  Target* = object
    name*: string
    kind*: TargetKind
    sources*: seq[SourceFile]
    compiler*: string
    flags*: seq[string]
    includes*: seq[string]
    defines*: seq[string]
    depends_on*: seq[string]
    link_flags*: seq[string]

  Project* = object
    name*: string
    targets*: seq[Target]

  BuildGraph* = object
    project*: Project

proc newBuildGraph*(project: Project): BuildGraph =
  BuildGraph(project: project)

proc getObjPath*(source: string): string =
  let dir = parentDir(source)
  let filename = changeFileExt(extractFilename(source), ".o")
  if dir == "" or dir == ".":
    return "build/obj/" & filename
  else:
    # Use joinPath logic or just ensure slash
    return "build/obj" / dir / filename

proc getOutputPath*(target: Target): string =
  case target.kind
  of tkExecutable:
    return "build/" & target.name
  of tkStatic:
    return "build/lib" & target.name & ".a"
  of tkShared:
    return "build/lib" & target.name & ".so"

proc needsRebuild*(source: string, outputPath: string): bool =
  if not fileExists(outputPath):
    return true
  
  let sourceTime = getLastModificationTime(source)
  let outputTime = getLastModificationTime(outputPath)
  
  return sourceTime > outputTime

proc targetNeedsRebuild*(target: Target): bool =
  let outputPath = getOutputPath(target)
  
  if not fileExists(outputPath):
    return true
  
  let outputTime = getLastModificationTime(outputPath)
  for source in target.sources:
    if getLastModificationTime(source.path) > outputTime:
      return true
  
  return false