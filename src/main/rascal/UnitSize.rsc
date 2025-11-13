module UnitSize

import Helpers;
import IO;
import List;
import Map;
import Set;
import String;
import lang::java::m3::Core;
import lang::java::m3::AST;


// 3. Unit Size (LOC per method)

// Definition: lines of code per unit (unit = method). Quality measured via a risk profile over “small/medium/large/very large” based on LOC thresholds, similar to complexity risk profiles.

// 3.1 unitSize_collectRaw(m3)

// Goal: LOC per method.

// Initialize map unitLoc : Method -> int

// For each Java method u in the M3 model:

// Get its src location (startLine..endLine)

// Count non-comment, non-blank LOC within that span

// Set unitLoc[u] = loc

// Return unitLoc

// (You may choose to exclude method declarations that are generated, synthetic, etc.)

// 3.2 unitSize_buildProfile(unitLoc)

// Goal: build a risk profile: % of LOC in “small / moderate / large / huge” units.

// Define size categories (example, adapt to SIG thresholds if you find the exact ones):

// Small: 1–15 LOC

// Moderate: 16–30

// Large: 31–60

// Very large: >60

// Initialize counters:

// locSmall = locModerate = locLarge = locVeryLarge = 0

// totalUnitLOC = 0

// For each method u:

// l = unitLoc[u]

// Add l to totalUnitLOC

// If l <= 15 → locSmall += l

// Else if <= 30 → locModerate += l

// Else if <= 60 → locLarge += l

// Else → locVeryLarge += l

// Compute percentages:

// pSmall = 100 * locSmall / totalUnitLOC (not strictly needed)

// pModerate = 100 * locModerate / totalUnitLOC

// pLarge = 100 * locLarge / totalUnitLOC

// pVeryLarge = 100 * locVeryLarge / totalUnitLOC

// Return (pModerate, pLarge, pVeryLarge)

// (SIG’s model only uses the “risky” categories for rating, same as complexity. )

// 3.3 unitSize_rate(pModerate, pLarge, pVeryLarge)

// Goal: map profile to rating; conceptually same scheme as for complexity.

// Example thresholds (you can calibrate later):

// 5★: pModerate <= 25, pLarge == 0, pVeryLarge == 0

// 4★: pModerate <= 30, pLarge <= 5, pVeryLarge == 0

// 3★: pModerate <= 40, pLarge <= 10, pVeryLarge == 0

// 2★: pModerate <= 50, pLarge <= 15, pVeryLarge <= 5

// 1★: otherwise

// Pseudo-code: check from highest to lowest star, return first that matches.

// 3.4 unitSize_report(unitLoc, profile, rating)

// Goal: show summary and big units.

// Print percentages for each risk category and rating.

// Extract methods where unitLoc[u] exceeds some “large” threshold (e.g. >60 LOC).

// Sort them by LOC descending.

// Print top N with (className, methodName, LOC) and maybe their file & line.












// 3. Unit Size (LOC per method)
// 3.1 measureUnitSize(projectLoc : loc)

// Purpose: main entry for Unit Size metric.

// Pseudocode:

// function measureUnitSize(projectLoc):
//     m3 = createM3ModelForJava(projectLoc)

//     unitLoc = unitSize_collectRaw(m3)

//     (pModerate, pLarge, pVeryLarge) = unitSize_buildProfile(unitLoc)

//     rating = unitSize_rate(pModerate, pLarge, pVeryLarge)

//     unitSize_report(unitLoc, pModerate, pLarge, pVeryLarge, rating)

// 3.2 unitSize_collectRaw(M3 m3) -> map[Method,int] unitLoc

// Purpose: compute LOC per method.

// Pseudocode:

// function unitSize_collectRaw(m3):
//     unitLoc = empty map from Method to int

//     methods = list all methods from m3

//     for each method in methods:
//         // Get source region of this method
//         srcRegion = getSourceRegion(method)  // includes startLine, endLine, file

//         file = srcRegion.file
//         startLine = srcRegion.startLine
//         endLine = srcRegion.endLine

//         loc = 0

//         for lineNr from startLine to endLine:
//             text = get line lineNr from file

//             trimmed = text with whitespace removed at both ends

//             if trimmed is empty:
//                 continue

//             if trimmed is comment-only:
//                 continue

//             loc = loc + 1

//         unitLoc[method] = loc

//     return unitLoc

// 3.3 unitSize_buildProfile(map[Method,int] unitLoc) -> (real pModerate, real pLarge, real pVeryLarge)

// Purpose: compute risk profile based on method sizes.

// Pseudocode:

// // Example category thresholds; adapt if you have calibrated ones
// // small       :  1–15 LOC
// // moderate    : 16–30
// // large       : 31–60
// // very large  : > 60
// function unitSize_buildProfile(unitLoc):
//     locSmall = 0
//     locModerate = 0
//     locLarge = 0
//     locVeryLarge = 0
//     totalUnitLOC = 0

//     for each (method, loc) in unitLoc:
//         totalUnitLOC = totalUnitLOC + loc

//         if loc <= 15:
//             locSmall = locSmall + loc
//         else if loc <= 30:
//             locModerate = locModerate + loc
//         else if loc <= 60:
//             locLarge = locLarge + loc
//         else:
//             locVeryLarge = locVeryLarge + loc

//     if totalUnitLOC == 0:
//         return (0.0, 0.0, 0.0)

//     pModerate = 100.0 * locModerate / totalUnitLOC
//     pLarge = 100.0 * locLarge / totalUnitLOC
//     pVeryLarge = 100.0 * locVeryLarge / totalUnitLOC

//     return (pModerate, pLarge, pVeryLarge)

// 3.4 unitSize_rate(real pModerate, real pLarge, real pVeryLarge) -> int rating

// Purpose: map profile to 1–5 rating.

// Pseudocode:

// // Example profile thresholds; same shape as SIG complexity profiles
// function unitSize_rate(pModerate, pLarge, pVeryLarge):
//     // 5 stars: almost all LOC in small units
//     if pModerate <= 25 and pLarge == 0 and pVeryLarge == 0:
//         return 5

//     // 4 stars: small amount of LOC in large units
//     if pModerate <= 30 and pLarge <= 5 and pVeryLarge == 0:
//         return 4

//     // 3 stars: some LOC in large units, none in very large
//     if pModerate <= 40 and pLarge <= 10 and pVeryLarge == 0:
//         return 3

//     // 2 stars: more risk, some very large units allowed
//     if pModerate <= 50 and pLarge <= 15 and pVeryLarge <= 5:
//         return 2

//     // 1 star: anything worse
//     return 1

// 3.5 unitSize_report(map[Method,int] unitLoc, real pModerate, real pLarge, real pVeryLarge, int rating) -> void

// Purpose: print summary and list biggest methods.

// Pseudocode:

// function unitSize_report(unitLoc, pModerate, pLarge, pVeryLarge, rating):
//     print("=== Unit Size Metric ===")
//     print("Percentage of LOC in moderate-sized methods: " + format(pModerate, 1 decimal) + " %")
//     print("Percentage of LOC in large methods: " + format(pLarge, 1 decimal) + " %")
//     print("Percentage of LOC in very large methods: " + format(pVeryLarge, 1 decimal) + " %")
//     print("Rating (1–5): " + rating)
//     print("")

//     print("Largest methods (by LOC):")

//     // Build list of (method, loc)
//     methodList = list of (method, loc) from unitLoc

//     // Sort descending by loc
//     sort methodList by loc descending

//     maxToShow = minimum(10, size of methodList)

//     for i from 0 to maxToShow - 1:
//         (method, loc) = methodList[i]
//         print("  " + methodToString(method) + "  ->  " + loc + " LOC")