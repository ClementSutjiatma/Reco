//
//  Strings.swift
//  Reco
//
//  Created by Clement Arnett Sutjiatma on 8/27/18.
//  Copyright © 2018 Reco. All rights reserved.
//

import Foundation

extension String {
    func inserting(separator: String, every n: Int) -> (Int, String) {
        var result: String = ""
        var count: Int = 1
        let characters = Array(self.characters)
        stride(from: 0, to: characters.count, by: n).forEach {
            count += 1
            result += String(characters[$0..<min($0+n, characters.count)])
            if $0+n < characters.count {
                result += separator
            }
        }
        return (count, result)
    }
    var byWords: [String] {
        var byWords:[String] = []
        enumerateSubstrings(in: startIndex..<endIndex, options: .byWords) {
            guard let word = $0 else { return }
            print($1,$2,$3)
            byWords.append(word)
        }
        return byWords
    }
    func firstWords(_ max: Int) -> [String] {
        return Array(byWords.prefix(max))
    }
    var firstWord: String {
        return byWords.first ?? ""
    }
    func lastWords(_ max: Int) -> [String] {
        return Array(byWords.suffix(max))
    }
    var lastWord: String {
        return byWords.last ?? ""
    }
}
