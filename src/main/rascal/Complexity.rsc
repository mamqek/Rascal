module Complexity

import Helpers;
import IO;
import List;
import Map;
import Set;
import String;
import lang::java::m3::Core;
import lang::java::m3::AST;


// 4. Unit Complexity (Cyclomatic complexity per method)

// Definition: McCabe cyclomatic complexity per unit; classified into risk categories and then rated using a profile of LOC percentage per category.

// 4.1 complexity_collectRaw(m3)

// Goal: cyclomatic complexity per method.

// Initialize map unitCC : Method -> int

// For each Java method u:

// Compute cyclomatic complexity:

// cc = 1 + # of decision points in the method

// Count: if, for, while, do-while, case (non-default), catch, conditional ?:, short-circuit && and ||, etc.

// Set unitCC[u] = cc

// Return unitCC

// You can either:

// Use Rascal’s existing Java metrics if available, or

// Implement your own visitor over the method AST to count decision nodes.

// 4.2 complexity_buildProfile(unitCC, unitLoc)

// Goal: same quality profile idea as in the paper.

// Risk categories:

// Low: 1–10

// Moderate: 11–20

// High: 21–50

// Very high: >50

// Profile algorithm:

// Initialize locLow = locModerate = locHigh = locVeryHigh = 0

// totalUnitLOC = 0

// For each method u:

// cc = unitCC[u]

// loc = unitLoc[u] (use same LOC per method as in unit size)

// totalUnitLOC += loc

// If cc <= 10 → locLow += loc

// Else if <= 20 → locModerate += loc

// Else if <= 50 → locHigh += loc

// Else → locVeryHigh += loc

// Compute percentages:

// pModerate = 100 * locModerate / totalUnitLOC

// pHigh = 100 * locHigh / totalUnitLOC

// pVeryHigh = 100 * locVeryHigh / totalUnitLOC

// Return (pModerate, pHigh, pVeryHigh)

// 4.3 complexity_rate(pModerate, pHigh, pVeryHigh)

// Use SIG thresholds:

// 5★: pModerate <= 25, pHigh == 0, pVeryHigh == 0

// 4★: pModerate <= 30, pHigh <= 5, pVeryHigh == 0

// 3★: pModerate <= 40, pHigh <= 10, pVeryHigh == 0

// 2★: pModerate <= 50, pHigh <= 15, pVeryHigh <= 5

// 1★: otherwise

// Check in that order and return rating.

// 4.4 complexity_report(unitCC, unitLoc, profile, rating)

// Goal: show complexity footprint and most complex methods.

// Print percentages per risk category and the rating.

// Extract methods with unitCC[u] > 20 (high or very high risk).

// Sort by unitCC descending (break ties by LOC).

// Print top N with (className, methodName, CC, LOC).


// 4. Unit Complexity (Cyclomatic per method)
// 4.1 measureUnitComplexity(projectLoc : loc)

// Purpose: main entry for Unit Complexity metric.

// Pseudocode:

// function measureUnitComplexity(projectLoc):
//     m3 = createM3ModelForJava(projectLoc)

//     unitCC = complexity_collectRaw(m3)

//     // Reuse unit LOC from unit size (or compute again if you prefer)
//     unitLoc = unitSize_collectRaw(m3)

//     (pModerate, pHigh, pVeryHigh) = complexity_buildProfile(unitCC, unitLoc)

//     rating = complexity_rate(pModerate, pHigh, pVeryHigh)

//     complexity_report(unitCC, unitLoc, pModerate, pHigh, pVeryHigh, rating)

// 4.2 complexity_collectRaw(M3 m3) -> map[Method,int] unitCC

// Purpose: compute cyclomatic complexity per method.

// Pseudocode:

// // Cyclomatic complexity = 1 + #decisionPoints
// // Decision points: if, for, while, do-while, case (non-default),
// // conditional operator ?:, catch, &&, || etc.
// function complexity_collectRaw(m3):
//     unitCC = empty map from Method to int

//     methods = list all methods from m3

//     for each method in methods:
//         ast = get AST of this method body from m3

//         decisionCount = 0

//         // Traverse AST
//         visit all nodes in ast:
//             if node is an "if" statement:
//                 decisionCount = decisionCount + 1

//             else if node is a "for" statement:
//                 decisionCount = decisionCount + 1

//             else if node is a "while" statement:
//                 decisionCount = decisionCount + 1

//             else if node is a "do-while" statement:
//                 decisionCount = decisionCount + 1

//             else if node is a "switch case" (non-default case label):
//                 decisionCount = decisionCount + 1

//             else if node is a "catch" clause:
//                 decisionCount = decisionCount + 1

//             else if node is a conditional operator "? :":
//                 decisionCount = decisionCount + 1

//             else if node is a logical AND operator "&&":
//                 decisionCount = decisionCount + 1

//             else if node is a logical OR operator "||":
//                 decisionCount = decisionCount + 1

//         cc = 1 + decisionCount

//         unitCC[method] = cc

//     return unitCC

// 4.3 complexity_buildProfile(map[Method,int] unitCC, map[Method,int] unitLoc) -> (real pModerate, real pHigh, real pVeryHigh)

// Purpose: compute risk profile over complexity categories weighted by LOC.

// Pseudocode:

// // Categories:
// // low       :  1–10
// // moderate  : 11–20
// // high      : 21–50
// // very high : > 50
// function complexity_buildProfile(unitCC, unitLoc):
//     locLow = 0
//     locModerate = 0
//     locHigh = 0
//     locVeryHigh = 0
//     totalUnitLOC = 0

//     for each (method, cc) in unitCC:
//         // look up LOC for this method
//         loc = unitLoc[method]  // assume every method in unitCC is present in unitLoc

//         totalUnitLOC = totalUnitLOC + loc

//         if cc <= 10:
//             locLow = locLow + loc
//         else if cc <= 20:
//             locModerate = locModerate + loc
//         else if cc <= 50:
//             locHigh = locHigh + loc
//         else:
//             locVeryHigh = locVeryHigh + loc

//     if totalUnitLOC == 0:
//         return (0.0, 0.0, 0.0)

//     pModerate = 100.0 * locModerate / totalUnitLOC
//     pHigh = 100.0 * locHigh / totalUnitLOC
//     pVeryHigh = 100.0 * locVeryHigh / totalUnitLOC

//     return (pModerate, pHigh, pVeryHigh)

// 4.4 complexity_rate(real pModerate, real pHigh, real pVeryHigh) -> int rating

// Purpose: map complexity profile to 1–5 rating.

// Pseudocode:

// // Same threshold shape as before (can tune values)
// function complexity_rate(pModerate, pHigh, pVeryHigh):
//     if pModerate <= 25 and pHigh == 0 and pVeryHigh == 0:
//         return 5

//     if pModerate <= 30 and pHigh <= 5 and pVeryHigh == 0:
//         return 4

//     if pModerate <= 40 and pHigh <= 10 and pVeryHigh == 0:
//         return 3

//     if pModerate <= 50 and pHigh <= 15 and pVeryHigh <= 5:
//         return 2

//     return 1

// 4.5 complexity_report(map[Method,int] unitCC, map[Method,int] unitLoc, real pModerate, real pHigh, real pVeryHigh, int rating) -> void

// Purpose: print a summary and most complex methods.

// Pseudocode:

// function complexity_report(unitCC, unitLoc, pModerate, pHigh, pVeryHigh, rating):
//     print("=== Unit Complexity Metric ===")
//     print("Percentage of LOC in moderate complexity (11–20): "
//           + format(pModerate, 1 decimal) + " %")
//     print("Percentage of LOC in high complexity (21–50): "
//           + format(pHigh, 1 decimal) + " %")
//     print("Percentage of LOC in very high complexity (>50): "
//           + format(pVeryHigh, 1 decimal) + " %")
//     print("Rating (1–5): " + rating)
//     print("")

//     print("Most complex methods:")

//     // Build list of (method, cc, loc)
//     methodList = empty list
//     for each (method, cc) in unitCC:
//         loc = unitLoc[method]
//         append (method, cc, loc) to methodList

//     // Sort descending by cc, then by loc
//     sort methodList by cc descending, then by loc descending

//     maxToShow = minimum(10, size of methodList)

//     for i from 0 to maxToShow - 1:
//         (method, cc, loc) = methodList[i]
//         print("  " + methodToString(method)
//               + "  ->  CC = " + cc
//               + ", LOC = " + loc)


int countDecisionPoints(Declaration d) {
  int count = 0;

  // Visit the declaration’s AST and increment when you see an if‐statement:
  visit(d) {
    case \if(_, _): 
        count = count + 1;
    case \if(_, _, _): 
        count = count + 1;
    case \for(_, _, _): 
        count = count + 1;
    case \for(_, _, _, _): 
        count = count + 1;
    case \foreach(_, _, _):
        count = count + 1;
    case \while(_, _): 
        count = count + 1;
    case \do(_, _):
        count = count + 1;
    case \catch(_, _):
        count = count + 1;
    case \switch(_, _):
        count = count + 1;
    case \case(_):
        count = count + 1;
    case \caseRule(_):
        count = count + 1;
    case \defaultCase():
        count = count + 1;
  }

    return count;
}