import std/[strutils, tables]

type
  NodeKind* = enum
    nkStmtList,
    nkAssignment,
    nkCommand,
    nkIfStmt,
    nkBinaryExpr,
    nkString,
    nkBoolean,
    nkList,
    nkVariable

  ASTNode* = ref object
    line*: int
    col*: int
    case kind*: NodeKind
    of nkStmtList:
      children*: seq[ASTNode]
    of nkAssignment:
      varName*: string
      assignmentValue*: ASTNode
    of nkCommand:
      cmdName*: string
      args*: seq[ASTNode]
      body*: ASTNode # Optional block
    of nkIfStmt:
      condition*: ASTNode
      ifBody*: ASTNode
      elseBody*: ASTNode
    of nkBinaryExpr:
      op*: string
      left*: ASTNode
      right*: ASTNode
    of nkString:
      strVal*: string
    of nkBoolean:
      boolVal*: bool
    of nkList:
      listElems*: seq[ASTNode]
    of nkVariable:
      varId*: string

proc newStmtList*(line, col: int): ASTNode =
  ASTNode(kind: nkStmtList, line: line, col: col, children: @[])

proc newAssignment*(line, col: int, name: string, val: ASTNode): ASTNode =
  ASTNode(kind: nkAssignment, line: line, col: col, varName: name, assignmentValue: val)

proc newCommand*(line, col: int, name: string, args: seq[ASTNode] = @[], body: ASTNode = nil): ASTNode =
  ASTNode(kind: nkCommand, line: line, col: col, cmdName: name, args: args, body: body)

proc newIfStmt*(line, col: int, cond, ifB: ASTNode, elseB: ASTNode = nil): ASTNode =
  ASTNode(kind: nkIfStmt, line: line, col: col, condition: cond, ifBody: ifB, elseBody: elseB)

proc newBinaryExpr*(line, col: int, op: string, left, right: ASTNode): ASTNode =
  ASTNode(kind: nkBinaryExpr, line: line, col: col, op: op, left: left, right: right)

proc newString*(line, col: int, val: string): ASTNode =
  ASTNode(kind: nkString, line: line, col: col, strVal: val)

proc newBoolean*(line, col: int, val: bool): ASTNode =
  ASTNode(kind: nkBoolean, line: line, col: col, boolVal: val)

proc newList*(line, col: int, elems: seq[ASTNode]): ASTNode =
  ASTNode(kind: nkList, line: line, col: col, listElems: elems)

proc newVariable*(line, col: int, id: string): ASTNode =
  ASTNode(kind: nkVariable, line: line, col: col, varId: id)
