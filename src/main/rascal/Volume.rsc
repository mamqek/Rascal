module Volume

import Helpers;
import IO;
import List;
import Map;
import Set;
import String;
import lang::java::m3::Core;
import lang::java::m3::AST;


// 1. Volume (Estimated rebuild value)

// Definition: total non-comment, non-blank LOC, optionally turned into man-years using the Programming Languages Table; for Java they use KLOC→man-years thresholds.

// 1.1 volume_collectRaw(project)

// Goal: compute per-file LOC and system LOC.

// Pseudo-code (English):

// Initialize totalLOC = 0

// Initialize map moduleLoc : Module -> int

// For each Java source file f in the project:

// Read file contents

// For each line:

// If line is not blank and not a comment line:

// moduleLoc[f] += 1

// totalLOC += 1

// Return (totalLOC, moduleLoc)

// (In Rascal you’ll likely reuse M3’s containment + src locations, and a helper countLOC(loc).)

// 1.2 volume_buildProfile(totalLOC, language)

// Goal: convert LOC to estimated man-years using SPR table, and prepare data for rating.

// Look up LOC per function point and FP per person-month for the language (Java).

// Compute function points ≈ fp = totalLOC / LOCperFP

// Compute person-months ≈ pm = fp / FPperMonth

// Compute man-years ≈ my = pm / 12

// Return my

// If you don’t want function points: you can directly use thresholds in LOC for Java from the paper.

// 1.3 volume_rate(my, language)

// Goal: map man-years (or KLOC) to 1–5 level (or ++/…/--).

// From the table in Heitlager for Java:

// Java LOC ⇒ man-years ranges (already calibrated):

// Rank	Man-years	Java KLOC (approx)
// ++	0–8	0–66
// +	8–30	66–246
// o	30–80	246–665
// -	80–160	665–1,310
// --	>160	>1,310

// Pseudo-code:

// If my <= 8 → rating = 5 (or ++)

// Else if my <= 30 → rating = 4 (or +)

// Else if my <= 80 → rating = 3 (or o)

// Else if my <= 160→ rating = 2 (or -)

// Else → rating = 1 (or --)

// Return rating

// 1.4 volume_report(totalLOC, my, rating, moduleLoc)

// Goal: give a human-readable summary and highlight “too big” modules.

// Print total LOC, estimated man-years, and rating.

// Sort modules by moduleLoc descending.

// Print top N modules (e.g. 10) with their LOC.

// Optionally mark modules that exceed some local volume threshold (e.g. > 10k LOC).








// 1. Volume
// 1.1 measureVolume(projectLoc : loc)

// Purpose: main entry for Volume metric. Takes loc, does everything, and prints.

// Pseudocode:

// function measureVolume(projectLoc):
//     language = "Java"  // or detect from projectLoc

//     (totalLOC, moduleLoc) = volume_collectRaw(projectLoc)

//     manYears = volume_buildProfile(totalLOC, language)

//     rating = volume_rate(manYears, language)

//     volume_report(totalLOC, manYears, rating, moduleLoc)

// 1.2 volume_collectRaw(projectLoc : loc) -> (int totalLOC, map[Module,int] moduleLoc)

// Purpose: count non-comment, non-blank LOC per file and system total.

// Pseudocode:

// function volume_collectRaw(projectLoc):
//     totalLOC = 0
//     moduleLoc = empty map from Module to int

//     files = list all Java source files under projectLoc

//     for each file in files:
//         module = module identifier for this file
//         moduleLoc[module] = 0

//         lines = read file into list of strings, one per line

//         for each line in lines:
//             trimmed = line with leading and trailing whitespace removed

//             if trimmed is empty:
//                 continue  // skip blank

//             if trimmed starts with a line comment marker:
//                 continue  // e.g. "//" in Java

//             if this line is inside a block comment:
//                 continue  // e.g. between "/*" and "*/"

//             // Otherwise it is a code line
//             moduleLoc[module] = moduleLoc[module] + 1
//             totalLOC = totalLOC + 1

//     return (totalLOC, moduleLoc)

// 1.3 volume_buildProfile(int totalLOC, str language) -> real manYears

// Purpose: convert LOC to man-years (estimated rebuild effort).

// Pseudocode:

// function volume_buildProfile(totalLOC, language):
//     if totalLOC == 0:
//         return 0.0

//     // Look up conversion parameters for this language
//     LOCperFunctionPoint = lookup_LOC_per_FP_for(language)
//     functionPointsPerPersonMonth = lookup_FP_per_PM_for(language)

//     // Estimate function points
//     fp = totalLOC / LOCperFunctionPoint

//     // Estimate person-months
//     personMonths = fp / functionPointsPerPersonMonth

//     // Convert to man-years
//     manYears = personMonths / 12.0

//     return manYears

// 1.4 volume_rate(real manYears, str language) -> int rating

// Purpose: map man-years to 1–5 rating.

// Pseudocode:

// // Example thresholds (Java-like); adapt if needed
// function volume_rate(manYears, language):
//     if manYears <= 8:
//         return 5   // excellent / ++
//     else if manYears <= 30:
//         return 4   // good
//     else if manYears <= 80:
//         return 3   // moderate
//     else if manYears <= 160:
//         return 2   // poor
//     else:
//         return 1   // very poor

// 1.5 volume_report(int totalLOC, real manYears, int rating, map[Module,int] moduleLoc) -> void

// Purpose: print a human-readable report for volume.

// Pseudocode:

// function volume_report(totalLOC, manYears, rating, moduleLoc):
//     print("=== Volume Metric ===")
//     print("Total LOC: " + totalLOC)
//     print("Estimated rebuild effort: " + format(manYears, 1 decimal) + " man-years")
//     print("Rating (1–5): " + rating)

//     // Show largest modules
//     print("")
//     print("Top modules by LOC:")

//     // Convert map to list of (module, loc) and sort descending by loc
//     items = list of (module, loc) from moduleLoc
//     sort items by loc descending

//     maxToShow = minimum(10, size of items)

//     for i from 0 to maxToShow - 1:
//         (module, loc) = items[i]
//         print("  " + moduleToString(module) + "  ->  " + loc + " LOC")