//
//  Brand.swift
//  ExpirationDateMonitor
//
//  Created by Shachar Erez on 11/23/20.
//

import Foundation

struct Brand {
    let name: String?

    init(data: [String: AnyObject]) {
        if let name = data["name"] as? String {
            self.name = name
        } else { self.name = nil }
    }
}
