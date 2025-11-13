module Metrics

import Helpers;
import IO;
import List;
import Map;
import Set;
import String;
import lang::java::m3::Core;
import lang::java::m3::AST;


import UnitSize;
import Complexity;
import JavaAnalysis;
import Duplication;

void run(loc projectLoc) {
  println("Collecting ASTs...");
  list[Declaration] asts = buildAsts(projectLoc);
  println("Number of ASTs: <size(asts)>");

  println("Measuring Unit Size...");
  measureUnitSize(projectLoc);
  println("Measuring Unit Complexity...");
  measureUnitComplexity(projectLoc);
  println("Measuring Code Duplication...");
  measureCodeDuplication(projectLoc);
  println("Measuring Volume");
  measureVolume(projectLoc);
}


void main() {
  println("");
  println("Running metrics for smallsql0.21_src");
  run(|project://smallsql0.21_src/|);

  println("");
  println("Running metrics for hsqldb-2.3.1");
  run(|project://hsqldb-2.3.1/|);
}
