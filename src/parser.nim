import lexer, ast, help, std/[terminal, strutils]

type
  Parser* = object
    lexer: Lexer
    curr: Token

proc advance(p: var Parser) =
  p.curr = p.lexer.nextToken()

proc error(p: Parser, msg: string) =
  displayError("Line " & $p.curr.line & ", Col " & $p.curr.col & ": " & msg)
  quit(1)

proc expect(p: var Parser, kind: TokenKind, msg: string) =
  if p.curr.kind != kind:
    p.error(msg & " (Got " & $p.curr.kind & ")")
  p.advance()

proc parseExpression(p: var Parser): ASTNode
proc parseBlock(p: var Parser): ASTNode

proc parseCall(p: var Parser, name: string, line, col: int): ASTNode =
  var args: seq[ASTNode] = @[]
  
  # Check if it's a call with parentheses
  if p.curr.kind == tkParenOpen:
    p.advance()
    while p.curr.kind != tkParenClose and p.curr.kind != tkEOF:
      args.add(p.parseExpression())
      if p.curr.kind == tkComma:
        p.advance()
    p.expect(tkParenClose, "Expected ')'")
  else:
    # Space-separated args (CMake/original Eikofile style)
    # This makes it very flexible
    while p.curr.kind in {tkString, tkIdentifier, tkTrue, tkFalse} and p.curr.line == line:
      args.add(p.parseExpression())
      if p.curr.kind == tkComma: p.advance()

  var body: ASTNode = nil
  if p.curr.kind == tkColon:
    p.advance()
    body = p.parseBlock()
    
  return newCommand(line, col, name, args, body)

proc parseBlock(p: var Parser): ASTNode =
  let line = p.curr.line
  let col = p.curr.col
  
  # Consume potential newlines before Indent
  while p.curr.kind == tkNewline: p.advance()
  
  p.expect(tkIndent, "Expected indentation for block")
  result = newStmtList(line, col)
  while p.curr.kind != tkDedent and p.curr.kind != tkEOF:
    if p.curr.kind == tkNewline:
      p.advance()
      continue
    result.children.add(p.parseExpression())
  p.expect(tkDedent, "Expected dedent")

proc parsePrimary(p: var Parser): ASTNode =
  let line = p.curr.line
  let col = p.curr.col
  
  case p.curr.kind
  of tkString:
    result = newString(line, col, p.curr.value)
    p.advance()
  of tkTrue, tkFalse:
    result = newBoolean(line, col, p.curr.kind == tkTrue)
    p.advance()
  of tkIdentifier:
    let id = p.curr.value
    p.advance()
    if p.curr.kind == tkAssign:
      p.advance()
      result = newAssignment(line, col, id, p.parseExpression())
    elif p.curr.kind == tkParenOpen or p.curr.kind == tkColon or (p.curr.kind in {tkIdentifier, tkString} and p.curr.line == line):
      result = p.parseCall(id, line, col)
    else:
      result = newVariable(line, col, id)
  of tkIf:
    p.advance()
    let cond = p.parseExpression()
    if p.curr.kind == tkColon: p.advance()
    let ifB = p.parseBlock()
    var elseB: ASTNode = nil
    if p.curr.kind == tkElse:
      p.advance()
      if p.curr.kind == tkIf: # else if
        elseB = p.parseExpression()
      elif p.curr.kind == tkColon:
        p.advance()
        elseB = p.parseBlock()
      else:
        elseB = p.parseBlock()
    result = newIfStmt(line, col, cond, ifB, elseB)
  of tkNewline:
    p.advance()
    return p.parsePrimary()
  else:
    p.error("Unexpected token: " & $p.curr.kind)

proc parseExpression(p: var Parser): ASTNode =
  result = p.parsePrimary()
  
  while p.curr.kind in {tkEquals, tkNotEquals}:
    let op = if p.curr.kind == tkEquals: "==" else: "!="
    let line = p.curr.line
    let col = p.curr.col
    p.advance()
    let right = p.parsePrimary()
    result = newBinaryExpr(line, col, op, result, right)

proc parseProject*(content: string): ASTNode =
  var p = Parser(lexer: newLexer(content))
  p.advance()
  
  result = newStmtList(1, 1)
  while p.curr.kind != tkEOF:
    if p.curr.kind == tkNewline:
      p.advance()
      continue
    result.children.add(p.parseExpression())
