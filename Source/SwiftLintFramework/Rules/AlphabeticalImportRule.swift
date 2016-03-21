//
//  AlphabeticalImportRule.swift
//  SwiftLint
//
//  Created by Christopher Jones on 2/22/16.
//  Copyright © 2016 Realm. All rights reserved.
//

import AVFoundation
import CoreLocation
import Foundation
import GameKit
import SourceKittenFramework

public final class AlphabeticalImportRule: CorrectableRule {

    public static var description = RuleDescription(
        identifier: "alphabetical_imports",
        name: "Alphabetical Imports",
        description: "Imports should be listed in alphabetical order.",
        nonTriggeringExamples: ["import A\n import B\n",
                                "import A\n @testable import C\n import B"],
        triggeringExamples:  ["import B\n import A"]
    )

    // swiftlint:disable:next force_try
    private static let regularExpression = regex("^(?:\\s)*(import.*)")

    public  var configurationDescription: String = "Hi"

    public init() {

    }

    public init(configuration: AnyObject) throws {

    }

    public func validateFile(file: File) -> [StyleViolation] {
        var violations = [StyleViolation]()

        var importLines = importsByLine(inFile: file)

        guard !importLines.isEmpty else {
            return violations
        }

        let sorted = sortImports(inLines: importLines)

        for (index, sortedLine) in sorted.enumerate() {
            let original = importLines[index]

            guard original.content != sortedLine.content else {
                continue
            }

            let violation = StyleViolation(ruleDescription: AlphabeticalImportRule.description,
                location: Location(file: file, characterOffset: original.range.location))
            violations.append(violation)
            break
        }

        return violations
    }

    public func isEqualTo(rule: Rule) -> Bool {
        return self.dynamicType.description == rule.dynamicType.description
    }

    public func correctFile(file: File) -> [Correction] {
        guard !validateFile(file).isEmpty else {
            return [Correction]()
        }

        let originalLines = importsByLine(inFile: file)
        let sortedLines = sortImports(inLines: originalLines)

        let placeholder = { (index: Int) -> String in
            return "{IMPORT_\(index)}"
        }

        var contents = file.contents
        for (index, line) in originalLines.enumerate() {
            contents = contents
                .stringByReplacingOccurrencesOfString(line.content, withString: placeholder(index))
        }

        for (index, line) in  sortedLines.enumerate() {
            contents = contents
                .stringByReplacingOccurrencesOfString(placeholder(index), withString: line.content)
        }

        file.write(contents)

        let correction = Correction(ruleDescription: AlphabeticalImportRule.description,
            location: Location(file: file, characterOffset: originalLines[0].range.location))

        return [correction]
    }

    private func importsByLine(inFile file: File) -> [Line] {
        return file.lines.filter { line in
            return !AlphabeticalImportRule.regularExpression
                .matchesInString(line.content,
                        options: NSMatchingOptions(rawValue: 0),
                        range: NSRange(location: 0, length: line.content.characters.count))
                .isEmpty
        }
            .filter { line in
                return !file.syntaxKindsByLine()[line.index].contains(SyntaxKind.Comment)
        }
    }

    private func sortImports(inLines lines: [Line]) -> [Line] {
        return lines.sort { (first, second) in
            return first.content.trim()
                .compare(second.content.trim()) == .OrderedAscending
        }
    }

}

private extension String {

    func trim() -> String {
        return stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
    }

}
