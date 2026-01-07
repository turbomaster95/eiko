# API Manifest for Eiko Build System
# All exported symbols must be declared here.

# cli.nim
proc build*(buildSystem: var BuildSystem)
proc clean*()
proc graph*(buildSystem: BuildSystem)

# build_graph.nim
proc newBuildGraph*(project: Project): BuildGraph
proc getObjPath*(source: string): string
proc getOutputPath*(target: Target): string
proc needsRebuild*(source: string, outputPath: string): bool
proc targetNeedsRebuild*(target: Target): bool

# executor.nim
proc newExecutor*(): Executor
proc compileSource*(executor: Executor, source: SourceFile, target: Target, objPath: string)
proc linkObjects*(executor: Executor, target: Target, objPaths: seq[string], depPaths: seq[string], outputPath: string)

# eikofile_parser.nim
proc parseEikofile*(filename: string): Project

# ast.nim
proc newStmtList*(line, col: int): ASTNode
proc newAssignment*(line, col: int, name: string, val: ASTNode): ASTNode
proc newCommand*(line, col: int, name: string, args: seq[ASTNode] = @[], body: ASTNode = nil): ASTNode
proc newIfStmt*(line, col: int, cond, ifB: ASTNode, elseB: ASTNode = nil): ASTNode
proc newBinaryExpr*(line, col: int, op: string, left, right: ASTNode): ASTNode
proc newString*(line, col: int, val: string): ASTNode
proc newBoolean*(line, col: int, val: bool): ASTNode
proc newList*(line, col: int, elems: seq[ASTNode]): ASTNode
proc newVariable*(line, col: int, id: string): ASTNode

# lexer.nim
proc newLexer*(content: string): Lexer
proc nextToken*(l: var Lexer): Token

# parser.nim
proc parseProject*(content: string): ASTNode

# evaluator_ast.nim
proc newEvaluator*(): Evaluator
proc evaluate*(node: ASTNode): Project

# bootstrap.nim
proc newBootstrap*(): Bootstrap
proc checkApiConsistency*(bootstrap: Bootstrap, manifestPath: string, sourceDir: string): bool
proc compileSelf*(bootstrap: Bootstrap, sourceDir: string, outputPath: string): bool
proc syncBinary*(bootstrap: Bootstrap, newBinaryPath: string, sourceDir: string): bool
proc getFileHash*(path: string): string
proc getSrcHash*(sourceDir: string): string

# help.nim
proc displayHelp*()
proc displayError*(msg: string)