module Duplication

import Helpers;
import IO;
import List;
import Map;
import Set;
import String;
import lang::java::m3::Core;
import lang::java::m3::AST;


// 2. Duplication (Redundancy)

// Definition (SIG): percentage of LOC that appears in duplicated blocks of ≥ 6 lines, comparing exact text modulo leading spaces.

// 2.1 duplication_collectRaw(project)

// Goal: detect duplicated blocks and mark which lines are in duplicates.

// High-level algorithm:

// Initialize sequence allNormalizedLines (each entry: (file, lineNumber, normalizedText))

// For each Java file:

// For each line:

// Remove leading whitespace

// Store (file, lineNr, normalizedLine) into allNormalizedLines

// Build all windows of 6 consecutive lines:

// For each index i from 0 to allNormalizedLines.size - 6:

// Let blockLines = lines[i..i+5]

// Concatenate the 6 normalizedText strings into a single blockKey

// Store in map blockKey -> list of occurrences

// Each occurrence is (file, startingLineNr, length=6)

// After scanning:

// For each blockKey where list of occurrences has size ≥ 2:

// For each occurrence (file, start, length):

// Mark lines [start .. start+length-1] in that file as duplicated.

// Count:

// duplicatedLines = number of distinct (file,lineNr) pairs marked duplicated

// totalLines = total number of non-comment, non-blank lines in the scope

// Return (duplicatedLines, totalLines)

// 2.2 duplication_buildProfile(duplicatedLines, totalLines)

// Goal: compute percentage of duplicated LOC.

// If totalLines == 0: duplicationPercent = 0

// Else: duplicationPercent = 100.0 * duplicatedLines / totalLines

// Return duplicationPercent

// 2.3 duplication_rate(duplicationPercent)

// Use SIG thresholds:

// 0–3% → rating 5 (or ++)

// 3–5% → rating 4 (or +)

// 5–10% → rating 3 (or o)

// 10–20% → rating 2 (or -)

// 20–100%→ rating 1 (or --)

// Pseudo-code:

// If duplicationPercent <= 3 → 5

// Else if <= 5 → 4

// Else if <= 10→ 3

// Else if <= 20→ 2

// Else → 1

// Return rating.

// 2.4 duplication_report(duplicationPercent, rating, duplicateBlocks)

// Goal: summarize and show worst clones.

// Print duplication percentage and rating.

// From duplicateBlocks (the map from blockKey to occurrences):

// Sort blocks by total duplicated LOC contributed (occurrenceCount * blockLength).

// For top N blocks:

// Print: number of occurrences, length (lines), and sample file & line.

// Optionally list files sorted by percentage duplicated lines.



// 2. Duplication
// 2.1 measureDuplication(projectLoc : loc)

// Purpose: main entry for Duplication metric.

// Pseudocode:

// function measureDuplication(projectLoc):
//     (duplicatedLines, totalLines, duplicateBlocks) = duplication_collectRaw(projectLoc)

//     duplicationPercent = duplication_buildProfile(duplicatedLines, totalLines)

//     rating = duplication_rate(duplicationPercent)

//     duplication_report(duplicationPercent, rating, duplicateBlocks)

// 2.2 duplication_collectRaw(projectLoc : loc) -> (int duplicatedLines, int totalLines, map[str,list[BlockOccurrence]] duplicateBlocks)

// Purpose: detect duplicated 6-line blocks and count duplicated lines.

// Pseudocode:

// // BlockOccurrence has fields: file, startLine, length
// function duplication_collectRaw(projectLoc):
//     allLines = empty list of (file, lineNumber, normalizedText)
//     totalLines = 0

//     files = list all Java source files under projectLoc

//     for each file in files:
//         lines = read file into list of strings, one per line
//         lineNumber = 1

//         for each line in lines:
//             trimmed = line with trailing newline removed

//             // Optionally skip comment-only or blank lines if you want duplication on code-only
//             // For SIG’s definition we normally count all non-blank non-comment lines

//             if trimmed is blank:
//                 lineNumber = lineNumber + 1
//                 continue

//             if trimmed is a comment-only line:
//                 lineNumber = lineNumber + 1
//                 continue

//             normalized = trimmed with leading whitespace removed

//             append (file, lineNumber, normalized) to allLines
//             totalLines = totalLines + 1
//             lineNumber = lineNumber + 1

//     // Now find duplicated 6-line blocks
//     duplicateBlocks = empty map from string to list of BlockOccurrence

//     // Need at least 6 lines to make one block
//     for i from 0 to (size of allLines - 6):
//         blockLines = allLines[i .. i+5]  // 6 consecutive entries

//         // Build a key representing these 6 lines
//         // Concatenate normalizedText with a separator
//         blockKey = ""
//         for each entry in blockLines:
//             blockKey = blockKey + entry.normalizedText + "\n"

//         occurrenceFile = blockLines[0].file
//         occurrenceStartLine = blockLines[0].lineNumber
//         occurrenceLength = 6

//         occurrence = BlockOccurrence(occurrenceFile, occurrenceStartLine, occurrenceLength)

//         if blockKey not in duplicateBlocks:
//             duplicateBlocks[blockKey] = empty list

//         append occurrence to duplicateBlocks[blockKey]

//     // Now mark which lines are in duplicated blocks
//     duplicatedLineSet = empty set of (file, lineNumber)

//     for each (blockKey, occurrences) in duplicateBlocks:
//         if size of occurrences < 2:
//             continue  // only interested in blocks that appear at least twice

//         for each occurrence in occurrences:
//             file = occurrence.file
//             startLine = occurrence.startLine
//             length = occurrence.length

//             for lineOffset from 0 to length - 1:
//                 lineNr = startLine + lineOffset
//                 add (file, lineNr) to duplicatedLineSet

//     duplicatedLines = size of duplicatedLineSet

//     return (duplicatedLines, totalLines, duplicateBlocks)

// 2.3 duplication_buildProfile(int duplicatedLines, int totalLines) -> real duplicationPercent

// Purpose: compute duplication percentage.

// Pseudocode:

// function duplication_buildProfile(duplicatedLines, totalLines):
//     if totalLines == 0:
//         return 0.0

//     duplicationPercent = 100.0 * duplicatedLines / totalLines

//     return duplicationPercent

// 2.4 duplication_rate(real duplicationPercent) -> int rating

// Purpose: map duplication % to 1–5 rating.

// Pseudocode:

// // Example SIG-like thresholds
// function duplication_rate(duplicationPercent):
//     if duplicationPercent <= 3.0:
//         return 5
//     else if duplicationPercent <= 5.0:
//         return 4
//     else if duplicationPercent <= 10.0:
//         return 3
//     else if duplicationPercent <= 20.0:
//         return 2
//     else:
//         return 1

// 2.5 duplication_report(real duplicationPercent, int rating, map[str,list[BlockOccurrence]] duplicateBlocks) -> void

// Purpose: print duplication summary and worst clone blocks.

// Pseudocode:

// function duplication_report(duplicationPercent, rating, duplicateBlocks):
//     print("=== Duplication Metric ===")
//     print("Duplication: " + format(duplicationPercent, 1 decimal) + " % of LOC")
//     print("Rating (1–5): " + rating)
//     print("")

//     print("Largest duplicated blocks (by total duplicated LOC):")

//     // Build a list of (blockKey, occurrences, totalDuplicatedLOC) for ranking
//     blockSummaries = empty list

//     for each (blockKey, occurrences) in duplicateBlocks:
//         if size of occurrences < 2:
//             continue  // not a clone

//         // Each occurrence is 6 lines here, but length can be stored in occurrence
//         anyOccurrence = occurrences[0]
//         blockLength = anyOccurrence.length

//         totalDuplicatedLOC = size of occurrences * blockLength

//         append (blockKey, occurrences, totalDuplicatedLOC) to blockSummaries

//     // Sort by totalDuplicatedLOC descending
//     sort blockSummaries by totalDuplicatedLOC descending

//     maxToShow = minimum(10, size of blockSummaries)

//     for i from 0 to maxToShow - 1:
//         (blockKey, occurrences, totalDuplicatedLOC) = blockSummaries[i]

//         sample = occurrences[0]
//         print("- Block with " + size of occurrences + " occurrences, "
//               + blockLength + " lines each, total duplicated LOC = "
//               + totalDuplicatedLOC)

//         print("  Example at " + fileToString(sample.file)
//               + " : line " + sample.startLine)