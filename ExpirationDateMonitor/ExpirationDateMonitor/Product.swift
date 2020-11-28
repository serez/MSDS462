//
//  Product.swift
//  sqliteplayground1
//
//  Created by Shachar Erez on 10/17/20.
//

import Foundation


class Product
{
    var id: Int = 0
    var name: String = ""
    var expirationDate: NSDate
    var warningNotificationId: String = ""
    var expirationNotificationId: String = ""
    
    
    init(id:Int, name:String, expirationDate: NSDate, warningNotificationId:String, expirationNotificationId:String)
    {
        self.id = id
        self.name = name
        self.expirationDate = expirationDate
        self.warningNotificationId = warningNotificationId
        self.expirationNotificationId = expirationNotificationId
    }
    
}
