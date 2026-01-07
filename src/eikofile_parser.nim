import std/os
import build_graph, parser, evaluator_ast

proc parseEikofile*(filename: string): Project =
  if not fileExists(filename):
    raise newException(IOError, "File not found: " & filename)
    
  let content = readFile(filename)
  let ast = parseProject(content)
  return evaluate(ast)
