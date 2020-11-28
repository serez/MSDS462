/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Utilities for dealing with recognized strings
*/

import Foundation

extension Character {
	// Given a list of allowed characters, try to convert self to those in list
	// if not already in it. This handles some common misclassifications for
	// characters that are visually similar and can only be correctly recognized
	// with more context and/or domain knowledge. Some examples (should be read
	// in Menlo or some other font that has different symbols for all characters):
	// 1 and l are the same character in Times New Roman
	// I and l are the same character in Helvetica
	// 0 and O are extremely similar in many fonts
	// oO, wW, cC, sS, pP and others only differ by size in many fonts
	func getSimilarCharacterIfNotIn(allowedChars: String) -> Character {
		let conversionTable = [
			"s": "S",
			"S": "5",
			"5": "S",
			"o": "O",
			"Q": "O",
			"O": "0",
			"0": "O",
			"l": "I",
			"I": "1",
			"1": "I",
			"B": "8",
			"8": "B"
		]
		// Allow a maximum of two substitutions to handle 's' -> 'S' -> '5'.
		let maxSubstitutions = 2
		var current = String(self)
		var counter = 0
		while !allowedChars.contains(current) && counter < maxSubstitutions {
			if let altChar = conversionTable[current] {
				current = altChar
				counter += 1
			} else {
				// Doesn't match anything in our table. Give up.
				break
			}
		}
		
		return current.first!
	}
}

extension String {
	// Extracts the first US-style phone number found in the string, returning
	// the range of the number and the number itself as a tuple.
	// Returns nil if no number is found.
	func extractExpirationDate() -> (Range<String.Index>, String, Date)? {
        
        let dateParser = DateddMMMYY()
        
        var pattern = dateParser.pattern
        
        //print("pattern: \(pattern)")
        
        var range = self.range(of: pattern, options: .regularExpression, range: nil, locale: nil)
        
        
        if(range == nil)
        {
           // print("No match found getPattern_mm_dd_YY")
            //return nil
            
            let dateParser2 = DatemmddYY()
            
            pattern = dateParser2.pattern
            
            //print("pattern: \(pattern)")
            
            range = self.range(of: pattern, options: .regularExpression, range: nil, locale: nil)
            
            if(range == nil)
            {
                return nil
            }
        }
        
        
        print("Found match!!!")
		
		// Potential expiration date found.
        let substring = String(self[range!])
        print("substring: \(substring)")
        
		let nsrange = NSRange(substring.startIndex..., in: substring)
    
        let matched = matches(for: pattern, in: substring)
        print(matched)
        
		do {
			// Tokenize date.
			let regex = try NSRegularExpression(pattern: pattern, options: [])
            print(regex.numberOfCaptureGroups)
            if let match = regex.firstMatch(in: substring, options: [], range: nsrange)
            {
                print("match.numberOfRanges: \(match.numberOfRanges)")
                for rangeInd in 1 ..< match.numberOfRanges
                {
                    print("Match number \(rangeInd)")
					let range = match.range(at: rangeInd)
                    //print("for 2")
                    if(range.location == NSNotFound)
                    {
                        print("range location not found")
                        continue
                    }
                    let matchString = (substring as NSString).substring(with: range)
                    print("matchstring: \(matchString)")
                    dateParser.parseData(data: matchString, index: rangeInd)
				}
			}
            else
            {
                print("No match")
            }
		} catch {
			print("Error \(error) when creating pattern")
		}
        
        print("Date as a number \(dateParser.getDate())")
        print("Date as a string \(dateParser.getDateAsString())")
		
		
        let result = dateParser.getDateAsString()
        let expTime = dateParser.getDate()
        
        print("expTime = \(expTime)")
        
        return (range, result, expTime) as? (Range<String.Index>, String, Date)
	}
    
    
    func matches(for regex: String, in text: String) -> [String] {

        do {
            let regex = try NSRegularExpression(pattern: regex)
            let results = regex.matches(in: text,
                                        range: NSRange(text.startIndex..., in: text))
            return results.map {
                String(text[Range($0.range, in: text)!])
            }
        } catch let error {
            print("invalid regex: \(error.localizedDescription)")
            return []
        }
    }
    
   /*
    func getPattern_dd_MMM_YYYY() -> (String)
    {
        return get_dd_pattern() + get_white_space() + get_MMM_pattern() +  get_white_space() + get_year_pattern()
    }
    
    func getPattern_mm_dd_YY() -> (String)
    {
        return get_mm_pattern() + get_white_space() + get_dd_pattern() +    get_white_space() + get_year_pattern()
    }
    
    
    func get_dd_pattern() -> (String)
    {
        return "(0[1-9]|[1-2][0-9]|3[01])"
    }
    
    func get_white_space() -> (String)
    {
        return "(\\s*)"
    }
    
    
    func get_MMM_pattern() -> (String)
    {
        return "(?i)(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)"
    }
    
    func get_mm_pattern() -> (String)
    {
        return "(0?[1-9])|1{1}[0-2]"
    }
    
    
    
    func get_year_pattern() -> (String)
    {
        return "((20)?\\d{2})"
    }
    
    
    func getPattern_phoneNumber() -> (String)
    {
        return #"""
        (?x)                    # Verbose regex, allows comments
        (?:\+1-?)?                # Potential international prefix, may have -
        [(]?                    # Potential opening (
        \b(\w{3})                # Capture xxx
        [)]?                    # Potential closing )
        [\ -./]?                # Potential separator
        (\w{3})                    # Capture xxx
        [\ -./]?                # Potential separator
        (\w{4})\b                # Capture xxxx
        """#
    }
 */
}

class StringTracker {
	var frameIndex: Int64 = 0

	typealias StringObservation = (lastSeen: Int64, count: Int64)
	
	// Dictionary of seen strings. Used to get stable recognition before
	// displaying anything.
	var seenStrings = [String: StringObservation]()
	var bestCount = Int64(0)
	var bestString = ""

	func logFrame(strings: [String]) {
		for string in strings {
			if seenStrings[string] == nil {
				seenStrings[string] = (lastSeen: Int64(0), count: Int64(-1))
			}
			seenStrings[string]?.lastSeen = frameIndex
			seenStrings[string]?.count += 1
			print("Seen \(string) \(seenStrings[string]?.count ?? 0) times")
		}
	
		var obsoleteStrings = [String]()

		// Go through strings and prune any that have not been seen in while.
		// Also find the (non-pruned) string with the greatest count.
		for (string, obs) in seenStrings {
			// Remove previously seen text after 30 frames (~1s).
			if obs.lastSeen < frameIndex - 30 {
				obsoleteStrings.append(string)
			}
			
			// Find the string with the greatest count.
			let count = obs.count
			if !obsoleteStrings.contains(string) && count > bestCount {
				bestCount = Int64(count)
				bestString = string
			}
		}
		// Remove old strings.
		for string in obsoleteStrings {
			seenStrings.removeValue(forKey: string)
		}
		
		frameIndex += 1
	}
	
	func getStableString() -> String? {
		// Require the recognizer to see the same string at least 10 times.
		if bestCount >= 1 {
			return bestString
		} else {
			return nil
		}
	}
	
	func reset(string: String) {
		seenStrings.removeValue(forKey: string)
		bestCount = 0
		bestString = ""
	}
}


class DateManager {
  static let shared = DateManager()
  private init() {}
  
  private let defaultDateFormat = "EEEE dd MMMM yyyy"
  
  private lazy var dateFormatter: DateFormatter = {
    let _dateFormatter = DateFormatter()
    _dateFormatter.locale = Bundle.main.preferredLocalizations.first.flatMap(Locale.init) ?? Locale.current
    
    return _dateFormatter
  }()
  
  func string(from date: Date, format: String? = nil) -> String {
    dateFormatter.dateFormat = format ?? defaultDateFormat
    return dateFormatter.string(from: date)
  }
  
  func date(from string: String, format: String? = nil) -> Date? {
    guard let dateFormat = format ?? dateFormat(for: string) else { return nil }
    
    dateFormatter.dateFormat = dateFormat
    return dateFormatter.date(from: string)
  }
  
  private func dateFormat(for string: String) -> String? {
    let dateFormats = [
      (dateFormat: "yyyyMMdd",
       regex: "^(19|20)\\d\\d(0[1-9]|1[012])(0[1-9]|[12][0-9]|3[01])$"),
      (dateFormat: "yyyy-MM-dd",
       regex: "^(19|20)\\d\\d-(0[1-9]|1[012])-(0[1-9]|[12][0-9]|3[01])$"),
      (dateFormat: "yyyy-MM-dd HH:mm:ss",
       regex: "^(19|20)\\d\\d-(0[1-9]|1[012])-(0[1-9]|[12][0-9]|3[01]) ([01][0-9]|2[0-3]):([0-5][0-9]):([0-5][0-9])$"),
      (dateFormat: "yyyyMMddHHmmss",
       regex: "^(19|20)\\d\\d(0[1-9]|1[012])(0[1-9]|[12][0-9]|3[01])([01][0-9]|2[0-3])([0-5][0-9])([0-5][0-9])$")
    ]
    
    return dateFormats
      .filter { string.range(of: $0.regex, options: .regularExpression) != nil }
      .first
      .map { $0.dateFormat }
  }
  
}

extension Date {
  var formattedString: String {
    return DateManager.shared.string(from: self)
  }
  
  var monthYearString: String {
    return DateManager.shared.string(from: self, format: "MMMM yyyy")
  }
}

extension String {
  var date: Date? {
    return DateManager.shared.date(from: self)
  }
}
