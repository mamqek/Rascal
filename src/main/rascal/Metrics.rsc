module Metrics

import IO;
import List;
import Map;
import Set;
import String;
import lang::java::m3::Core;
import lang::java::m3::AST;

//////////////////////////////
// 1) METRICS  (public API) //
//////////////////////////////

/// Volume: total LOC ~= count of non-blank, non-comment lines across all source files.
public int computeVolume(set[loc] sourceFiles) {
  int total = 0;
  for (f <- sourceFiles) {
    str raw = readFile(f);
    str noBlock = stripBlockComments(raw);           // shared helper
    for (l <- splitLines(noBlock)) {                  // shared helper
      if (!isCommentOrBlank(l)) {                     // shared helper
        total += 1;
      }
    }
  }
  return total;
}

/// Unit Size: statements per unit (method/constructor).
/// Returns: map[unitName -> statementCount]
public map[str,int] computeUnitSize(list[Declaration] asts) {
  map[str,int] sizes = ();
  for (m <- extractMethods(asts)) {                  // shared helper
    str name = methodName(m);                        // shared helper
    int stmtCount = countStatementsIn(m);            // local helper (placed next to this metric)
    sizes[name] = stmtCount;
  }
  return sizes;
}
// -- local (single-use) helper for Unit Size --
int countStatementsIn(Declaration d) = size([ s | /Statement s := d ]);


/// Unit Complexity: cyclomatic complexity per unit (approx):
///   complexity = 1 + (#if + #for + #foreach + #while + #doWhile + #catch + #case + #conditional)
/// Returns: map[unitName -> complexity]
public map[str,int] computeUnitComplexity(list[Declaration] asts) {
  map[str,int] cplx = ();
  for (m <- extractMethods(asts)) {                  // shared helper
    str name = methodName(m);                        // shared helper
    int decisions = countDecisionPoints(m);          // local helper (placed next to this metric)
    cplx[name] = 1 + decisions;
  }
  return cplx;
}
// -- local (single-use) helper for Unit Complexity --
int countDecisionPoints(Declaration d) {
  int nIf      = size([ x | /\if(_,_,_) := d ]);
  int nFor     = size([ x | /\for(_,_,_,_) := d ]);
  int nForEach = size([ x | /\foreach(_,_,_) := d ]);
  int nWhile   = size([ x | /\while(_,_) := d ]);
  int nDoWhile = size([ x | /\do(_,_) := d ]);
  int nCatch   = size([ x | /\catch(_,_) := d ]);
  int nCase    = size([ x | /\case(_,_) := d ]);
  int nCond    = size([ x | /\conditional(_,_,_) := d ]);
  return nIf + nFor + nForEach + nWhile + nDoWhile + nCatch + nCase + nCond;
}

/// Duplication: naive textual duplication across files:
///  - strip /*...*/
///  - ignore blank and // lines
///  - normalize whitespace per line
///  duplication% = 100 * (sum(max(0, count(line)-1)) / total_kept_lines)
public real computeDuplicationPercent(set[loc] sourceFiles) {
  map[str,int] lineFreq = ();
  int kept = 0;

  for (f <- sourceFiles) {
    str raw = readFile(f);
    str noBlock = stripBlockComments(raw);          // shared helper
    for (l <- splitLines(noBlock)) {                 // shared helper
      if (isCommentOrBlank(l)) continue;            // shared helper
      str norm = normalizeLine(l);                  // shared helper
      if (norm == "") continue;
      lineFreq[norm] = (norm in lineFreq ? lineFreq[norm] + 1 : 1);
      kept += 1;
    }
  }

  if (kept == 0) return 0.0;
  int dupExcess = sum([cnt - 1 | int cnt <- lineFreq.values(), cnt > 1]);
  return (100.0 * dupExcess) / kept;
}


//////////////////////////////////////////////
// 2) HELPERS (Shared and Local placement)  //
//////////////////////////////////////////////

// ===== Shared helpers (used by multiple metrics) =====

// Build once in main and pass results: provided here for main only.
list[Declaration] buildAsts(loc projectLoc) {
  M3 model = createM3FromMavenProject(projectLoc);
  return [ createAstFromFile(f, true)
           | f <- files(model.containment), isCompilationUnit(f) ];
}

set[loc] collectSourceFiles(loc projectLoc) {
  M3 model = createM3FromMavenProject(projectLoc);
  return { f | f <- files(model.containment), isCompilationUnit(f) };
}

// Extract methods & ctors (used by Unit Size + Unit Complexity)
list[Declaration] extractMethods(list[Declaration] asts) {
  list[Declaration] ms = [];
  ms += [ d | /d:\methodDeclaration(_,_,_,_,_,_,_,_,_,_,_) := asts];
  ms += [ d | /d:\method(_,_,_) := asts];
  ms += [ d | /d:\constructorDeclaration(_,_,_,_,_,_,_,_,_) := asts];
  ms += [ d | /d:\constructor(_,_,_) := asts];
  return uniqueBySrc(ms);                           // shared helper
}

// Readable method/ctor name (used by multiple metrics)
str methodName(Declaration d) {
  switch (d) {
    case \methodDeclaration(_,_,\id(str n),_,_,_,_,_,_,_,_): return n;
    case \method(\id(str n),_,_):                            return n;
    case \constructorDeclaration(_,_,\id(str n),_,_,_,_,_,_): return "<init:" + n + ">";
    case \constructor(\id(str n),_,_):                       return "<init:" + n + ">";
    default:
      return "<unit@" + (d has src ? (d[src].path + ":" + toString(d[src].begin.line)) : "unknown") + ">";
  }
}

// Dedup by src (used by method extraction)
list[Declaration] uniqueBySrc(list[Declaration] ds) {
  set[str] seen = {};
  list[Declaration] out = [];
  for (d <- ds) {
    str key = d has src ? (d[src].path + ":" + toString(d[src].begin.line) + ":" + toString(d[src].end.line)) : toString(d);
    if (key notin seen) {
      seen += {key};
      out += [d];
    }
  }
  return out;
}

// Text processing helpers (used by Volume + Duplication)
list[str] splitLines(str s) = split(s, "\n");

bool isCommentOrBlank(str line) {
  str t = trim(line);
  return t == "" || startsWith(t, "//");
}

// Remove /* ... */ chunks (quick & practical; not a full lexer).
str stripBlockComments(str s) {
  str cur = s;
  while (true) {
    int start = findFirst(cur, "/*");
    if (start < 0) break;
    int end = findFirstFrom(cur, "*/", start + 2);
    if (end < 0) { cur = substring(cur, 0, start); break; }
    cur = substring(cur, 0, start) + substring(cur, end + 2, size(cur));
  }
  return cur;
}

int findFirst(str hay, str needle) {
  for (int i <- [0..size(hay) - size(needle)]) {
    if (substring(hay, i, i + size(needle)) == needle) return i;
  }
  return -1;
}

int findFirstFrom(str hay, str needle, int from) {
  for (int i <- [from..max(0, size(hay) - size(needle))]) {
    if (substring(hay, i, i + size(needle)) == needle) return i;
  }
  return -1;
}

str normalizeLine(str l) {
  str t = trim(l);
  return collapseSpaces(t);
}

str collapseSpaces(str s) {
  str out = "";
  bool inSpace = false;
  for (int i <- [0..size(s))) {
    str c = substring(s, i, i+1);
    bool sp = (c == " " || c == "\t" || c == "\r");
    if (sp) {
      if (!inSpace) { out += " "; inSpace = true; }
    } else {
      out += c; inSpace = false;
    }
  }
  return out;
}


// ===== (No more single-use helpers here: each sits next to its metric) =====


/////////////////////////////////////////////////////////
// 3) PRINTING (summary and small supportive functions) //
/////////////////////////////////////////////////////////

// Risk bucketing structs
data Bucket = Low() | Moderate() | High();
alias RiskSummary = tuple[int low, int moderate, int high];
alias RiskRule = int (int value);

// Thresholds (easy to tweak)
list[RiskRule] sizeRiskRules() = [
  (int v) { return v <= 10 ? 1 : 0; },
  (int v) { return v > 10 && v <= 30 ? 1 : 0; },
  (int v) { return v > 30 ? 1 : 0; }
];

list[RiskRule] complexityRiskRules() = [
  (int v) { return v <= 10 ? 1 : 0; },
  (int v) { return v > 10 && v <= 20 ? 1 : 0; },
  (int v) { return v > 20 ? 1 : 0; }
];

RiskSummary riskProfile(map[str,int] m, list[RiskRule] rules) {
  int low = 0; int mid = 0; int high = 0;
  for (v <- m.values()) {
    if (rules[0](v) == 1) low  += 1;
    else if (rules[1](v) == 1) mid   += 1;
    else if (rules[2](v) == 1) high  += 1;
  }
  return <low, mid, high>;
}

str renderRisk(RiskSummary r) {
  int total = r.low + r.moderate + r.high;
  if (total == 0) return "n/a";
  real l = (100.0 * r.low) / total;
  real m = (100.0 * r.moderate) / total;
  real h = (100.0 * r.high) / total;
  return "Low " + formatPercent(l) + ", Moderate " + formatPercent(m) + ", High " + formatPercent(h);
}

real averageIntMap(map[str,int] m) {
  if (size(m) == 0) return 0.0;
  return (1.0 * sum(m.values())) / size(m);
}

str formatPercent(real r) = "<(round(r * 10) / 10.0)>%";

void printTopN(str title, map[str,int] m, int n) {
  println(title + ":");
  list[tuple[str,int]] items = sort(descendingValues(toList(m)));
  int k = min(n, size(items));
  for (int i <- [0..k)) {
    tuple[str,int] t = items[i];
    println("  <i+1>. <t[0]>  =>  <t[1]>");
  }
}

list[tuple[str,int]] toList(map[str,int] m) = [<k, m[k]> | k <- m];

list[tuple[str,int]] descendingValues(list[tuple[str,int]] xs) =
  sort(xs, bool (tuple[str,int] a, tuple[str,int] b) { return a[1] > b[1]; });


/// One-shot runner: builds ASTs & source files ONCE, then passes to metrics.
public void printSeries1Report(loc projectLoc) {
  println("=== Series 1 Metrics ===");
  println("Project: <projectLoc>");
  println("");

  // Build once
  list[Declaration] asts = buildAsts(projectLoc);
  set[loc] sourceFiles = collectSourceFiles(projectLoc);

  // Metrics (no AST building inside)
  int volume = computeVolume(sourceFiles);
  map[str,int] sizeMap = computeUnitSize(asts);
  map[str,int] cplxMap = computeUnitComplexity(asts);
  real dupPct = computeDuplicationPercent(sourceFiles);

  // Print summary
  println("Volume (LOC)         : <volume>");
  println("Duplication (%)      : <formatPercent(dupPct)>");
  println("");

  RiskSummary sizeRisk = riskProfile(sizeMap, sizeRiskRules());
  println("-- Unit Size (statements per unit) --");
  println("Units                 : <size(sizeMap)>");
  println("Average               : <averageIntMap(sizeMap)>");
  println("Risk profile          : <renderRisk(sizeRisk)>");
  printTopN("Largest units", sizeMap, 5);
  println("");

  RiskSummary cplxRisk = riskProfile(cplxMap, complexityRiskRules());
  println("-- Unit Complexity (cyclomatic) --");
  println("Units                 : <size(cplxMap)>");
  println("Average               : <averageIntMap(cplxMap)>");
  println("Risk profile          : <renderRisk(cplxRisk)>");
  printTopN("Most complex units", cplxMap, 5);

  println("");
  println("=== End ===");
}

// Convenience alias
public void run(loc projectLoc) = printSeries1Report(projectLoc);

// Simple entry point, similar to JavaAnalysis.main
int main(int testArgument=0) {
  println("argument: <testArgument>");

  println("");
  println("Running metrics for smallsql0.21_src");
  run(|project://smallsql0.21_src/|);

  println("");
  println("Running metrics for hsqldb-2.3.1");
  run(|project://hsqldb-2.3.1/|);

  return testArgument;
}
