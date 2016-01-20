//
// NJOPasswordRule.swift
//
// Copyright (c) 2015 Jason Nam (http://www.jasonnam.com)
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.
//

import Foundation
#if os(OSX)
    import CoreServices
#else
    import UIKit
#endif

public protocol NJOPasswordRule {
    func evaluateWithString(string: String) -> Bool
    func localizedErrorDescription() -> String
}

public enum NJORequiredCharacterRulePreset {
    case LowercaseCharacter
    case UppercaseCharacter
    case DecimalDigitCharacter
    case SymbolCharacter
}

public class NJOAllowedCharacterRule: NSObject, NJOPasswordRule {
    private var disallowedCharacters: NSCharacterSet! = nil

    public convenience init(characterSet: NSCharacterSet) {
        self.init()
        disallowedCharacters = characterSet.invertedSet
    }

    public func evaluateWithString(string: String) -> Bool {
        if disallowedCharacters == nil {
            return false
        }

        return (string as NSString).rangeOfCharacterFromSet(disallowedCharacters).location != NSNotFound
    }

    public func localizedErrorDescription() -> String {
        return NSLocalizedString("NAVAJO_ALLOWED_CHARACTER_ERROR", tableName: nil, bundle: NSBundle.mainBundle(), value: "Must not include disallowed character", comment: "Navajo - Allowed character rule")
    }
}

public class NJORequiredCharacterRule: NSObject, NJOPasswordRule {
    private var _preset: NJORequiredCharacterRulePreset! = nil
    private var requiredCharacterSet: NSCharacterSet! = nil

    public convenience init(preset: NJORequiredCharacterRulePreset) {
        self.init()

        _preset = preset

        switch preset {
        case .LowercaseCharacter:
            requiredCharacterSet = NSCharacterSet.lowercaseLetterCharacterSet()
        case .UppercaseCharacter:
            requiredCharacterSet = NSCharacterSet.uppercaseLetterCharacterSet()
        case .DecimalDigitCharacter:
            requiredCharacterSet = NSCharacterSet.decimalDigitCharacterSet()
        case .SymbolCharacter:
            let symbolCharacterSet = NSMutableCharacterSet.symbolCharacterSet()
            symbolCharacterSet.formUnionWithCharacterSet(NSCharacterSet.punctuationCharacterSet())
            requiredCharacterSet = symbolCharacterSet
        }
    }

    public convenience init(characterSet: NSCharacterSet) {
        self.init()
        requiredCharacterSet = characterSet
    }

    public func evaluateWithString(string: String) -> Bool {
        if requiredCharacterSet == nil {
            return false
        }

        return (string as NSString).rangeOfCharacterFromSet(requiredCharacterSet).location == NSNotFound
    }

    public func localizedErrorDescription() -> String {
        if let preset = _preset {
            switch preset {
            case .LowercaseCharacter:
                return NSLocalizedString("NAVAJO_REQUIRED_CHARACTER_LOWERCASE_ERROR", tableName: nil, bundle: NSBundle.mainBundle(), value: "Must include lowercase characters", comment: "Navajo - Required lowercase character rule")
            case .UppercaseCharacter:
                return NSLocalizedString("NAVAJO_REQUIRED_CHARACTER_UPPERCASE_ERROR", tableName: nil, bundle: NSBundle.mainBundle(), value: "Must include uppercase characters", comment: "Navajo - Required uppercase character rule")
            case .DecimalDigitCharacter:
                return NSLocalizedString("NAVAJO_REQUIRED_CHARACTER_DECIMAL_DIGIT_ERROR", tableName: nil, bundle: NSBundle.mainBundle(), value: "Must include decimal digit characters", comment: "Navajo - Required decimal digit character rule")
            case .SymbolCharacter:
                return NSLocalizedString("NAVAJO_REQUIRED_CHARACTER_SYMBOL_ERROR", tableName: nil, bundle: NSBundle.mainBundle(), value: "Must include symbol characters", comment: "Navajo - Required symbol character rule")
            }
        } else {
            return NSLocalizedString("NAVAJO_REQUIRED_CHARACTER_REQUIRED_ERROR", tableName: nil, bundle: NSBundle.mainBundle(), value: "Must include required characters", comment: "Navajo - Required character rule")
        }
    }
}

public class NJODictionaryWordRule: NSObject, NJOPasswordRule {
    private var nonLowercaseCharacterSet = NSCharacterSet.lowercaseLetterCharacterSet().invertedSet

    public func evaluateWithString(string: String) -> Bool {
        #if os(OSX)
            return DCSGetTermRangeInString(nil, string, 0).location != kCFNotFound
        #else
            return UIReferenceLibraryViewController.dictionaryHasDefinitionForTerm(string.lowercaseString.stringByTrimmingCharactersInSet(nonLowercaseCharacterSet))
        #endif
    }

    public func localizedErrorDescription() -> String {
        return NSLocalizedString("NAVAJO_DICTIONARYWORD_ERROR", tableName: nil, bundle: NSBundle.mainBundle(), value: "Must not be dictionary word", comment: "Navajo - Dictionary word rule")
    }
}

public class NJOLengthRule: NSObject, NJOPasswordRule {
    private var _range: NSRange! = nil

    public convenience init(min: Int, max: Int) {
        self.init()
        _range = NSMakeRange(min, max - min + 1)
    }

    public func evaluateWithString(string: String) -> Bool {
        if _range == nil {
            return false
        }

        return !NSLocationInRange(string.characters.count, _range)
    }

    public func localizedErrorDescription() -> String {
        return NSLocalizedString("NAVAJO_LENGTH_ERROR", tableName: nil, bundle: NSBundle.mainBundle(), value: "Must be within range ", comment: "Navajo - Length rule") + NSStringFromRange(_range)
    }
}

public class NJOPredicateRule: NSObject, NJOPasswordRule {
    private var _predicate: NSPredicate! = nil

    public convenience init(predicate: NSPredicate) {
        self.init()
        _predicate = predicate
    }

    public func evaluateWithString(string: String) -> Bool {
        if _predicate == nil {
            return false
        }

        return _predicate.evaluateWithObject(string)
    }

    public func localizedErrorDescription() -> String {
        return NSLocalizedString("NAVAJO_PREDICATE_ERROR", tableName: nil, bundle: NSBundle.mainBundle(), value: "Must not match predicate", comment: "Navajo - Predicate rule")
    }
}

public class NJORegularExpressionRule: NSObject, NJOPasswordRule {
    private var _regularExpression: NSRegularExpression! = nil

    public convenience init(regularExpression: NSRegularExpression) {
        self.init()
        _regularExpression = regularExpression
    }

    public func evaluateWithString(string: String) -> Bool {
        if _regularExpression == nil {
            return false
        }

        return _regularExpression.numberOfMatchesInString(string, options: [], range: NSMakeRange(0, string.characters.count)) > 0
    }

    public func localizedErrorDescription() -> String {
        return NSLocalizedString("NAVAJO_REGEX_ERROR", tableName: nil, bundle: NSBundle.mainBundle(), value: "Must not match regular expression", comment: "Navajo - Regex rule")
    }
}

public class NJOBlockRule: NSObject, NJOPasswordRule {
    private var _evaluation: (String -> Bool)! = nil

    public convenience init(evaluation: String -> Bool) {
        self.init()
        _evaluation = evaluation
    }

    public func evaluateWithString(string: String) -> Bool {
        if _evaluation == nil {
            return false
        }

        return _evaluation(string)
    }

    public func localizedErrorDescription() -> String {
        return NSLocalizedString("NAVAJO_BLOCK_ERROR", tableName: nil, bundle: NSBundle.mainBundle(), value: "Must not satisfy precondition", comment: "Navajo - Block rule")
    }
}