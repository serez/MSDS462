//
//  DBHelper.swift
//  sqliteplayground1
//
//  Created by Shachar Erez on 10/17/20.
//

import Foundation
import SQLite3

class DBHelper
{
    init(isDemo: Bool)
    {
        db = openDatabase()
        if(isDemo)
        {
            deleteTable()
        }
        createTable()
        
    }

    let dbPath: String = "productDB.sqlite"
    var db:OpaquePointer?

    func openDatabase() -> OpaquePointer?
    {
        let fileURL = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
            .appendingPathComponent(dbPath)
        var db: OpaquePointer? = nil
        if sqlite3_open(fileURL.path, &db) != SQLITE_OK
        {
            print("error opening database")
            return nil
        }
        else
        {
            print("Successfully opened connection to database at \(dbPath)")
            return db
        }
    }
    
    
    
    
    
    
    func createTable() {
        let createTableString = "CREATE TABLE IF NOT EXISTS product(Id INTEGER PRIMARY KEY AUTOINCREMENT,Name TEXT,ExpirationDate DATE, WarningNotificationId TEXT, ExpirationNotificationId TEXT);"
        
        var createTableStatement: OpaquePointer? = nil
        if sqlite3_prepare_v2(db, createTableString, -1, &createTableStatement, nil) == SQLITE_OK
        {
            if sqlite3_step(createTableStatement) == SQLITE_DONE
            {
                print("product table created.")
            } else {
                print("product table could not be created.")
            }
        } else {
            print("CREATE TABLE statement could not be prepared.")
        }
        sqlite3_finalize(createTableStatement)
    }
    
    func deleteTable()
    {
        let deleteTableString = "DROP table product"
        
        var deleteTableStatement: OpaquePointer? = nil
        if sqlite3_prepare_v2(db, deleteTableString, -1, &deleteTableStatement, nil) == SQLITE_OK
        {
            if sqlite3_step(deleteTableStatement) == SQLITE_DONE
            {
                print("product table deleted.")
            } else {
                print("product table could not be deleted.")
            }
        } else {
            print("DROP TABLE statement could not be prepared.")
        }
        sqlite3_finalize(deleteTableStatement)
    }
    
    
    
    
    func insert(name:String, expirationDate:NSDate, warningNotificationId: String, expirationNotificationId: String)
    {
        let insertStatementString = "INSERT INTO product (Name, ExpirationDate, WarningNotificationId, ExpirationNotificationId) VALUES (?, ?, ?, ?);"
        var insertStatement: OpaquePointer? = nil
        if sqlite3_prepare_v2(db, insertStatementString, -1, &insertStatement, nil) == SQLITE_OK {
            sqlite3_bind_text(insertStatement, 1, (name as NSString).utf8String, -1, nil)
            sqlite3_bind_int(insertStatement, 2, Int32(expirationDate.timeIntervalSince1970))
            sqlite3_bind_text(insertStatement, 3, (warningNotificationId as NSString).utf8String, -1, nil)
            sqlite3_bind_text(insertStatement, 4, (expirationNotificationId as NSString).utf8String, -1, nil)
            
            
            if sqlite3_step(insertStatement) == SQLITE_DONE {
                print("Successfully inserted row.")
            } else {
                print("Could not insert row.")
            }
        } else {
            print("INSERT statement could not be prepared.")
        }
        sqlite3_finalize(insertStatement)
    }
    
    func read() -> [Product] {
        let queryStatementString = "SELECT Id, Name, ExpirationDate, WarningNotificationId, ExpirationNotificationId FROM product;"
        var queryStatement: OpaquePointer? = nil
        var psns : [Product] = []
        if sqlite3_prepare_v2(db, queryStatementString, -1, &queryStatement, nil) == SQLITE_OK {
            while sqlite3_step(queryStatement) == SQLITE_ROW {
                let id = sqlite3_column_int(queryStatement, 0)
                let name = String(describing: String(cString: sqlite3_column_text(queryStatement, 1)))
                let expirationDate = sqlite3_column_int(queryStatement, 2)
                let warningNotificationId = String(describing: String(cString: sqlite3_column_text(queryStatement, 3)))
                let expirationNotificationId = String(describing: String(cString: sqlite3_column_text(queryStatement, 4)))
                
                psns.append(Product(id: Int(id), name: name, expirationDate: NSDate(timeIntervalSince1970: TimeInterval(expirationDate)),
                                    warningNotificationId: warningNotificationId,
                                    expirationNotificationId: expirationNotificationId))
                
                print("Query Result:")
                print("\(id) | \(name) | \(expirationDate)")
            }
        } else {
            print("SELECT statement could not be prepared")
        }
        sqlite3_finalize(queryStatement)
        return psns
    }
    
    func readByAscDate() -> [Product] {
        let queryStatementString = "SELECT Id, Name, ExpirationDate, WarningNotificationId, ExpirationNotificationId FROM product ORDER BY ExpirationDate;"
        var queryStatement: OpaquePointer? = nil
        var psns : [Product] = []
        if sqlite3_prepare_v2(db, queryStatementString, -1, &queryStatement, nil) == SQLITE_OK {
            while sqlite3_step(queryStatement) == SQLITE_ROW {
                let id = sqlite3_column_int(queryStatement, 0)
                let name = String(describing: String(cString: sqlite3_column_text(queryStatement, 1)))
                let expirationDate = sqlite3_column_int(queryStatement, 2)
                let warningNotificationId = String(describing: String(cString: sqlite3_column_text(queryStatement, 3)))
                let expirationNotificationId = String(describing: String(cString: sqlite3_column_text(queryStatement, 4)))
                
                psns.append(Product(id: Int(id), name: name, expirationDate: NSDate(timeIntervalSince1970: TimeInterval(expirationDate)),
                                    warningNotificationId: warningNotificationId,
                                    expirationNotificationId: expirationNotificationId))
                
                print("Query Result:")
                print("\(id) | \(name) | \(expirationDate)")
            }
        } else {
            print("SELECT statement could not be prepared")
        }
        sqlite3_finalize(queryStatement)
        return psns
    }
    
    func deleteByID(id:Int) {
        let deleteStatementStirng = "DELETE FROM product WHERE Id = ?;"
        var deleteStatement: OpaquePointer? = nil
        if sqlite3_prepare_v2(db, deleteStatementStirng, -1, &deleteStatement, nil) == SQLITE_OK {
            sqlite3_bind_int(deleteStatement, 1, Int32(id))
            if sqlite3_step(deleteStatement) == SQLITE_DONE {
                print("Successfully deleted row.")
            } else {
                print("Could not delete row.")
            }
        } else {
            print("DELETE statement could not be prepared")
        }
        sqlite3_finalize(deleteStatement)
    }
    
}
