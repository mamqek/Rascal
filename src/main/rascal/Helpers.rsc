module Helpers

import IO;
import List;
import Map;
import Set;
import String;
import lang::java::m3::Core;
import lang::java::m3::AST;

list[Declaration] buildAsts(loc projectLoc) {
  M3 model = createM3FromMavenProject(projectLoc);
  return [ createAstFromFile(f, true)
           | f <- files(model.containment), isCompilationUnit(f) ];
}

set[loc] collectSourceFiles(loc projectLoc) {
  M3 model = createM3FromMavenProject(projectLoc);
  return { f | f <- files(model.containment), isCompilationUnit(f) };
}

list[Declaration] extractMethods(list[Declaration] asts) {
  list[Declaration] result = [];

  for (d <- asts) {
    visit(d) {
      case method(_, _, _, _, _, _):
        result = result + [d];
      case method(_, _, _, _, _, _, _):
        result = result + [d];
    }
  }

  return result;
}

str methodName(Declaration d) {
  str result;
  switch (d) {
    case method(_, _, _, \id(n), _, _):
      result = n;
    case method(_, _, _, \id(n), _, _, _):
      result = n;
    default:
      result = "unknown";
  }

  return result;
}