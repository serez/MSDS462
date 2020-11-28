//
//  DateRegex.swift
//  RealtimeNumberReader
//
//  Created by Shachar Erez on 11/7/20.
//  Copyright © 2020 Apple. All rights reserved.
//

import Foundation

class DateRegex
{
    var pattern : String
    var day : Int
    var month : Int
    var year : Int
    
    init()
    {
        pattern = ""
        day = 1
        month = 1
        year = 2020
    }
    
    
    func parseData(data : String, index : Int)
    {
        // This should be handled in the inherited classes
    }
    
    func getDate() -> (Date)
    {
        let calendar = Calendar.current

        var components = DateComponents()

        components.day = self.day
        components.month = self.month
        components.year = self.year

        return calendar.date(from: components)!
    }
    
    func getDateAsString() -> (String)
    {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .none
         
         
        // US English Locale (en_US)
        //dateFormatter.locale = Locale(identifier: "en_US")
        return dateFormatter.string(from: getDate())
         
    }
    
    
    internal func get_dd_pattern() -> (String)
    {
        return "(0[1-9]|[1-2][0-9]|3[01])"
    }
    
    internal func get_white_space() -> (String)
    {
        return "(\\s*)"
    }
    
    
    internal func get_MMM_pattern() -> (String)
    {
        return "(?i)(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)"
    }
    
    internal func get_mm_pattern() -> (String)
    {
        return "((0?[1-9])|1{1}[0-2])"
    }
    
    
    
    internal func get_year_pattern() -> (String)
    {
        return "((20)?\\d{2})"
    }
    
    
    internal func getHyphen() -> (String)
    {
        return "(-)"
    }
    
    internal func setDay(data: String)
    {
        self.day = Int(data) ?? 1
    }
    
    
    internal func handleWhiteSpace(data : String)
    {
        // Do nothing
    }
    
    internal func handleHyphen(data: String)
    {
        // Do nothing
    }
    
    internal func setYear(data : String)
    {
        self.year = Int(data) ?? 1970
        if(self.year < 100)
        {
            year += 2000
        }
    }
    
    
    
    internal func setMonth(data : String)
    {
        self.month = Int(data) ?? 1
    }
    
}


class DateddMMMYY: DateRegex
{
    override init()
    {
        super.init()
        pattern = get_dd_pattern() + get_white_space() + get_MMM_pattern() +  get_white_space() + get_year_pattern()
    }
    
    
    override func parseData(data : String, index : Int)
    {
        switch index
        {
        case 1:
            setDay(data: data)
        case 2:
            handleWhiteSpace(data: data)
        case 3:
            setMonth(data: data)
        case 4:
            handleWhiteSpace(data: data)
        case 5:
            setYear(data: data)
        default:
            // do nothing
            break
        }
        
    }
    
    
    override internal func setMonth(data : String)
    {
        let m = data.lowercased()
        
        switch m
        {
        case "jan":
            self.month = 1
        case "feb":
            self.month = 2
        case "mar":
            self.month = 3
        case "apr":
            self.month = 4
        case "may":
            self.month = 5
        case "jun":
            self.month = 6
        case "jul":
            self.month = 7
        case "aug":
            self.month = 8
        case "sep":
            self.month = 9
        case "oct":
            self.month = 10
        case "nov":
            self.month = 11
        case "dec":
            self.month = 12
        default:
            self.month = 1
        }
        
    }
}



class DatemmddYY: DateRegex
{
    override init()
    {
        super.init()
        pattern = get_mm_pattern() + get_white_space() + getHyphen() + get_white_space() + get_dd_pattern() + get_white_space() +  getHyphen() + get_white_space() + get_year_pattern()
       // pattern = get_mm_pattern() +  getHyphen() +  get_dd_pattern() + get_white_space() +  getHyphen() + get_year_pattern()
    }
    
    
    override func parseData(data : String, index : Int)
    {
        switch index
        {
        case 1:
            setMonth(data: data)
        case 2:
            handleWhiteSpace(data: data)
        case 3:
            handleHyphen(data: data)
        case 4:
            handleWhiteSpace(data: data)
        case 5:
            setDay(data: data)
        case 6:
            handleWhiteSpace(data: data)
        case 7:
            handleHyphen(data: data)
        case 8:
            handleWhiteSpace(data: data)
        case 9:
            setYear(data: data)
        default:
            // do nothing
            break
        }
    }
    
}



class DateMMMddYY: DateRegex
{
    override init()
    {
        super.init()
        pattern = get_MMM_pattern()  + get_white_space() + get_dd_pattern() +  get_white_space() + get_year_pattern()
    }
    
    
    override func parseData(data : String, index : Int)
    {
        switch index
        {
        case 1:
            setMonth(data: data)
        case 2:
            handleWhiteSpace(data: data)
        case 3:
            setDay(data: data)
        case 4:
            handleWhiteSpace(data: data)
        case 5:
            setYear(data: data)
        default:
            // do nothing
            break
        }
        
    }
    
    
    override internal func setMonth(data : String)
    {
        let m = data.lowercased()
        
        switch m
        {
        case "jan":
            self.month = 1
        case "feb":
            self.month = 2
        case "mar":
            self.month = 3
        case "apr":
            self.month = 4
        case "may":
            self.month = 5
        case "jun":
            self.month = 6
        case "jul":
            self.month = 7
        case "aug":
            self.month = 8
        case "sep":
            self.month = 9
        case "oct":
            self.month = 10
        case "nov":
            self.month = 11
        case "dec":
            self.month = 12
        default:
            self.month = 1
        }
        
    }
}



