//
//  TransformationString.swift
//  Transforms
//
//  Created by David M Reed on 12/18/21.
//

import SwiftUI

extension Bool {
    var negated: Bool { return !self }
}

extension StringProtocol where Self: RangeReplaceableCollection {
    var removingAllWhitespaces: Self {
        filter(\.isWhitespace.negated)
    }
    mutating func removeAllWhitespaces() {
        removeAll(where: \.isWhitespace)
    }
}

struct TransformationString {
    
    enum ParseError: Error {
        case nan
        case incorrectCountOfNumbers
    }
    
    let s: String
    
    init(_ transformationString: String) {
        s = transformationString
    }
    
    func parse() throws -> CGAffineTransform {
        var t = CGAffineTransform.identity
        let terms = s.removingAllWhitespaces.components(separatedBy: "*")
        for term in terms.reversed() {
            let noParen = term.dropFirst().replacingOccurrences(of: "(", with: "").replacingOccurrences(of: ")", with: "")
            if term.first == "S" {
                let values = try parseNumbers(noParen, count: 2)
                t = t.concatenating(CGAffineTransform(scaleX: values[0], y: values[1]))
            } else if term.first == "T" {
                let values = try parseNumbers(noParen, count: 2)
                t = t.concatenating(CGAffineTransform(translationX: values[0], y: values[1]))
            } else if term.first == "R" {
                let values = try parseNumbers(noParen, count: 1)
                t = t.concatenating(CGAffineTransform(rotationAngle: values[0] * CGFloat.pi / 180.0))
            }
        }
        return t
    }
    
    private func parseNumbers<T: StringProtocol>(_ s: T, count: Int = 1) throws -> [Double] {
        let terms = s.components(separatedBy: ",")
        if terms.count != count {
            throw ParseError.incorrectCountOfNumbers
        }
        do {
            let values = terms.compactMap { Double($0) }
            if values.count != count {
                throw ParseError.nan
            }
            return values
        }
    }
}
