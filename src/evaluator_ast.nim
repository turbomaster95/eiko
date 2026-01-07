import std/[tables, strutils, sequtils]
import ast, build_graph

type
  Scope = ref object
    vars: Table[string, ASTNode]
    parent: Scope

  Evaluator* = object
    project*: Project
    scope: Scope
    currentTarget: ptr Target
    # Global settings
    globalCompiler: string
    globalFlags: seq[string]
    globalIncludes: seq[string]
    globalDefines: seq[string]

proc newEvaluator*(): Evaluator =
  Evaluator(
    project: Project(name: "unnamed"),
    scope: Scope(vars: initTable[string, ASTNode]()),
    currentTarget: nil,
    globalFlags: @[],
    globalIncludes: @[],
    globalDefines: @[]
  )

proc eval(ev: var Evaluator, node: ASTNode): ASTNode

proc resolveVar(ev: Evaluator, id: string): ASTNode =
  var curr = ev.scope
  while curr != nil:
    if curr.vars.hasKey(id):
      return curr.vars[id]
    curr = curr.parent
  return nil

proc evalToBool(ev: var Evaluator, node: ASTNode): bool =
  let val = ev.eval(node)
  if val == nil: return false
  case val.kind
  of nkBoolean: return val.boolVal
  of nkString: return val.strVal != ""
  else: return true

proc evalAsString(ev: var Evaluator, node: ASTNode): string =
  let val = ev.eval(node)
  if val == nil: return ""
  case val.kind
  of nkString: return val.strVal
  of nkBoolean: return $val.boolVal
  of nkVariable: return ev.evalAsString(ev.resolveVar(val.varId))
  else: return ""

proc evalStmtList(ev: var Evaluator, node: ASTNode) =
  if node == nil: return
  for child in node.children:
    discard ev.eval(child)

proc evalBinary(ev: var Evaluator, node: ASTNode): ASTNode =
  let left = ev.eval(node.left)
  let right = ev.eval(node.right)
  
  if left == nil or right == nil: return newBoolean(node.line, node.col, false)
  
  case node.op
  of "==":
    if left.kind == nkString and right.kind == nkString:
      return newBoolean(node.line, node.col, left.strVal == right.strVal)
    if left.kind == nkBoolean and right.kind == nkBoolean:
      return newBoolean(node.line, node.col, left.boolVal == right.boolVal)
  of "!=":
    if left.kind == nkString and right.kind == nkString:
      return newBoolean(node.line, node.col, left.strVal != right.strVal)
  
  return newBoolean(node.line, node.col, false)

proc evalCommand(ev: var Evaluator, node: ASTNode) =
  case node.cmdName
  of "project":
    if node.args.len > 0:
      ev.project.name = ev.evalAsString(node.args[0])
  of "executable", "static", "shared":
    var kind = tkExecutable
    if node.cmdName == "static": kind = tkStatic
    elif node.cmdName == "shared": kind = tkShared
    
    let name = ev.evalAsString(node.args[0])
    # Initialize with global defaults
    var target = Target(
      name: name, 
      kind: kind,
      compiler: ev.globalCompiler,
      flags: ev.globalFlags,
      includes: ev.globalIncludes,
      defines: ev.globalDefines
    )
    ev.project.targets.add(target)
    
    let oldTarget = ev.currentTarget
    ev.currentTarget = addr ev.project.targets[^1]
    
    let oldScope = ev.scope
    ev.scope = Scope(vars: initTable[string, ASTNode](), parent: oldScope)
    
    if node.body != nil:
      ev.evalStmtList(node.body)
      
    ev.scope = oldScope
    ev.currentTarget = oldTarget
    
  of "sources":
    if ev.currentTarget != nil:
      for arg in node.args:
        ev.currentTarget.sources.add(SourceFile(path: ev.evalAsString(arg)))
  of "compiler":
    let val = ev.evalAsString(node.args[0])
    if ev.currentTarget != nil:
      ev.currentTarget.compiler = val
    else:
      ev.globalCompiler = val
  of "flags":
    if ev.currentTarget != nil:
      for arg in node.args:
        ev.currentTarget.flags.add(ev.evalAsString(arg))
    else:
      for arg in node.args:
        ev.globalFlags.add(ev.evalAsString(arg))
  of "include":
    if ev.currentTarget != nil:
      for arg in node.args:
        ev.currentTarget.includes.add(ev.evalAsString(arg))
    else:
      for arg in node.args:
        ev.globalIncludes.add(ev.evalAsString(arg))
  of "define":
    if ev.currentTarget != nil:
      for arg in node.args:
        ev.currentTarget.defines.add(ev.evalAsString(arg))
    else:
      for arg in node.args:
        ev.globalDefines.add(ev.evalAsString(arg))
  of "depends_on":
    if ev.currentTarget != nil:
      for arg in node.args:
        ev.currentTarget.depends_on.add(ev.evalAsString(arg))
  of "print":
    var output = ""
    for arg in node.args:
      output.add(ev.evalAsString(arg) & " ")
    echo "[EIKO PRINT] ", output.strip()
  else:
    discard

proc eval(ev: var Evaluator, node: ASTNode): ASTNode =
  if node == nil: return nil
  case node.kind
  of nkStmtList:
    ev.evalStmtList(node)
  of nkAssignment:
    let val = ev.eval(node.assignmentValue)
    ev.scope.vars[node.varName] = val
  of nkCommand:
    ev.evalCommand(node)
  of nkIfStmt:
    if ev.evalToBool(node.condition):
      ev.evalStmtList(node.ifBody)
    else:
      ev.evalStmtList(node.elseBody)
  of nkBinaryExpr:
    return ev.evalBinary(node)
  of nkVariable:
    return ev.resolveVar(node.varId)
  of nkString, nkBoolean, nkList:
    return node
  else:
    discard
  return nil

proc evaluate*(node: ASTNode): Project =
  var ev = newEvaluator()
  discard ev.eval(node)
  return ev.project
