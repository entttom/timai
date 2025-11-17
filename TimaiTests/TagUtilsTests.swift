//
//  TagUtilsTests.swift
//  TimaiTests
//
//  Einfache Unit-Tests für TagUtils
//

import XCTest
@testable import Timai

final class TagUtilsTests: XCTestCase {
    
    func testTagsFromString_trimsAndRemovesDuplicates() {
        let input = " Tag1 ,tag2,  Tag1 , ,TAG2 "
        let result = TagUtils.tags(from: input)
        
        XCTAssertEqual(result.count, 2)
        XCTAssertTrue(result.contains(where: { $0.caseInsensitiveCompare("Tag1") == .orderedSame }))
        XCTAssertTrue(result.contains(where: { $0.caseInsensitiveCompare("tag2") == .orderedSame }))
    }
    
    func testStringFromTags_buildsCommaSeparated() {
        let input = [" Tag1 ", "tag2", "TAG1", ""]
        let result = TagUtils.string(from: input)
        
        XCTAssertEqual(result, "Tag1, tag2")
    }
    
    func testRoundtrip() {
        let original = ["Dev", "Backend", "Swift"]
        let string = TagUtils.string(from: original)
        let roundtrip = TagUtils.tags(from: string)
        
        XCTAssertEqual(roundtrip.count, 3)
        for tag in original {
            XCTAssertTrue(roundtrip.contains(where: { $0.caseInsensitiveCompare(tag) == .orderedSame }))
        }
    }
}


