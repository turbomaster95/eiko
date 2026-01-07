import std/[strutils, sequtils]

type
  TokenKind* = enum
    tkIdentifier, tkString, tkAssign, tkEquals, tkNotEquals,
    tkParenOpen, tkParenClose,
    tkIndent, tkDedent,
    tkComma, tkComment, tkColon,
    tkIf, tkElse, tkTrue, tkFalse,
    tkEOF, tkNewline

  Token* = object
    kind*: TokenKind
    value*: string
    line*: int
    col*: int

  Lexer* = object
    content*: string
    pos*: int
    line*: int
    col*: int
    indentStack: seq[int]
    pendingTokens: seq[Token]
    atLineStart: bool

proc newLexer*(content: string): Lexer =
  Lexer(
    content: content, 
    pos: 0, 
    line: 1, 
    col: 1, 
    indentStack: @[0], 
    pendingTokens: @[],
    atLineStart: true
  )

proc advance(l: var Lexer) =
  if l.pos < l.content.len:
    if l.content[l.pos] == '\n':
      inc l.line
      l.col = 1
    else:
      inc l.col
    inc l.pos

proc peek(l: Lexer, offset: int = 0): char =
  if l.pos + offset >= l.content.len: return '\0'
  return l.content[l.pos + offset]

proc lexIdentifier(l: var Lexer): Token =
  result.line = l.line
  result.col = l.col
  var val = ""
  while l.pos < l.content.len and (l.peek() in {'a'..'z', 'A'..'Z', '0'..'9', '_'}):
    val.add(l.peek())
    l.advance()
  
  result.value = val
  case val
  of "if": result.kind = tkIf
  of "else": result.kind = tkElse
  of "true": result.kind = tkTrue
  of "false": result.kind = tkFalse
  else: result.kind = tkIdentifier

proc lexString(l: var Lexer): Token =
  result.line = l.line
  result.col = l.col
  result.kind = tkString
  let quote = l.peek()
  l.advance()
  var val = ""
  while l.pos < l.content.len and l.peek() != quote:
    if l.peek() == '\\':
      l.advance()
      case l.peek()
      of 'n': val.add('\n')
      of 't': val.add('\t')
      of 'r': val.add('\r')
      else: val.add(l.peek())
    else:
      val.add(l.peek())
    l.advance()
  
  if l.peek() == quote: l.advance()
  result.value = val

proc nextToken*(l: var Lexer): Token =
  if l.pendingTokens.len > 0:
    let t = l.pendingTokens[0]
    l.pendingTokens.delete(0)
    return t

  while l.pos < l.content.len:
    if l.atLineStart:
      l.atLineStart = false
      var currentIndent = 0
      while l.pos < l.content.len and (l.peek() == ' ' or l.peek() == '\t'):
        if l.peek() == ' ': currentIndent += 1
        else: currentIndent += 4
        l.advance()
      
      # Skip empty lines or comments
      if l.pos >= l.content.len or l.peek() == '\n' or l.peek() == '#':
        if l.pos < l.content.len and l.peek() == '#':
           while l.pos < l.content.len and l.peek() != '\n': l.advance()
        if l.pos < l.content.len and l.peek() == '\n':
          l.advance()
          l.atLineStart = true
          continue
        elif l.pos >= l.content.len: break
      
      let lastIndent = l.indentStack[^1]
      if currentIndent > lastIndent:
        l.indentStack.add(currentIndent)
        return Token(kind: tkIndent, line: l.line, col: l.col)
      elif currentIndent < lastIndent:
        while l.indentStack.len > 1 and l.indentStack[^1] > currentIndent:
          discard l.indentStack.pop()
          l.pendingTokens.add(Token(kind: tkDedent, line: l.line, col: l.col))
        if l.pendingTokens.len > 0:
          let t = l.pendingTokens[0]
          l.pendingTokens.delete(0)
          return t

    let c = l.peek()
    case c
    of ' ', '\t', '\r':
      l.advance()
      continue
    of '\n':
      l.advance()
      l.atLineStart = true
      return Token(kind: tkNewline, line: l.line, col: l.col)
    of '#':
      while l.pos < l.content.len and l.peek() != '\n':
        l.advance()
      l.atLineStart = true
      continue
    of '=':
      if l.peek(1) == '=':
        result = Token(kind: tkEquals, line: l.line, col: l.col)
        l.advance(); l.advance()
      else:
        result = Token(kind: tkAssign, line: l.line, col: l.col)
        l.advance()
      return
    of '!':
      if l.peek(1) == '=':
        result = Token(kind: tkNotEquals, line: l.line, col: l.col)
        l.advance(); l.advance()
        return
      l.advance(); continue
    of '(':
      result = Token(kind: tkParenOpen, line: l.line, col: l.col)
      l.advance(); return
    of ')':
      result = Token(kind: tkParenClose, line: l.line, col: l.col)
      l.advance(); return
    of ':':
      result = Token(kind: tkColon, line: l.line, col: l.col)
      l.advance(); return
    of ',':
      result = Token(kind: tkComma, line: l.line, col: l.col)
      l.advance(); return
    of '"', '\'':
      return l.lexString()
    else:
      if c in {'a'..'z', 'A'..'Z', '_'}:
        return l.lexIdentifier()
      l.advance()
  
  # Emit remaining dedents at EOF
  while l.indentStack.len > 1:
    discard l.indentStack.pop()
    l.pendingTokens.add(Token(kind: tkDedent, line: l.line, col: l.col))
  
  if l.pendingTokens.len > 0:
    let t = l.pendingTokens[0]
    l.pendingTokens.delete(0)
    return t
    
  return Token(kind: tkEOF, line: l.line, col: l.col)
