//
//  ViewController.swift
//  ExpirationDateMonitor
//
//  Created by Shachar Erez on 11/19/20.
//

import UIKit


class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UNUserNotificationCenterDelegate, ProductInfoDelegate {
    
    
    
    
    
    
    
    
    @IBOutlet weak var productTable: UITableView!
    
    
    
    let cellReuseIdentifier = "cell"
    
    let isDemo = true
        
    var db:DBHelper = DBHelper(isDemo: true)
        
    var products:[Product] = []
    
    var currentProduct: Product = Product(id: 0, name: "", expirationDate: NSDate(timeIntervalSince1970: 0), warningNotificationId: "", expirationNotificationId: "")

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        self.productTable.register(UITableViewCell.self, forCellReuseIdentifier: cellReuseIdentifier)
        self.productTable.delegate = self
        self.productTable.dataSource = self
        
        self.productTable.rowHeight = 80
        
        if(isDemo)
        {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
                
            var stringDate = "2019-10-10"
            var date = dateFormatter.date(from: stringDate)
            addProductInfo(name: "Cottage cheese", expirationDate: date!)
           
            
            stringDate = "2020-11-23"
            date = dateFormatter.date(from: stringDate)
            addProductInfo(name: "Eggs", expirationDate: date!)
           
            
            
            stringDate = "2020-11-21"
            date = dateFormatter.date(from: stringDate)
            addProductInfo(name: "Milk", expirationDate: date!)
            
            
            stringDate = "2020-11-22"
            date = dateFormatter.date(from: stringDate)
            addProductInfo(name: "Chicken", expirationDate: date!)
            
            
        }
        
                
        products = db.readByAscDate()
        
    
        requestNotificationPermission()

    }
    
    func setExpirationDate(date: Date) {
        print("View Controller - setExpirationDate")
        currentProduct.expirationDate = date as NSDate
    }
    
    func setProductName(name: String) {
        currentProduct.name = name
    }
    
    func onProductInfoReady()
    {
        if(currentProduct.expirationDate.timeIntervalSince1970 == 0 || currentProduct.name.isEmpty)
        {
            print("currentProduct is missing information")
            return
        }
        addProductInfo(name: currentProduct.name, expirationDate: currentProduct.expirationDate as Date)
        products = db.readByAscDate()
        print(products)
        if(self.productTable == nil)
        {
            print("productTable is nil")
        }
        self.productTable.reloadData()
        self.productTable.refreshControl?.endRefreshing()
        
        resetCurrentProduct()
    }
    
    
    
    func resetCurrentProduct()
    {
        self.currentProduct.expirationDate = NSDate(timeIntervalSince1970: 0)
        self.currentProduct.expirationNotificationId = ""
        self.currentProduct.name = ""
        self.currentProduct.warningNotificationId = ""
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return products.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell:UITableViewCell = tableView.dequeueReusableCell(withIdentifier: cellReuseIdentifier)!
                
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM-dd-yyyy"
        let stringDate: String = dateFormatter.string(from: products[indexPath.row].expirationDate as Date)
        
        print("Reading date from db:")
        print(products[indexPath.row].expirationDate)
        
        cell.textLabel?.numberOfLines = 0
        cell.textLabel?.lineBreakMode =  NSLineBreakMode.byWordWrapping

        
        
        cell.textLabel?.text = products[indexPath.row].name + " " + "expirationDate: " + stringDate
        
        let t = NSDate.now
        
        let components = NSCalendar.current
        
        if(components.isDateInTomorrow(products[indexPath.row].expirationDate as Date)
            || components.isDateInToday(products[indexPath.row].expirationDate as Date))
        {
            let backgroundView = UIView()
            backgroundView.backgroundColor = UIColor.yellow
            cell.backgroundView = backgroundView
        }
        else if(products[indexPath.row].expirationDate.timeIntervalSince1970 < t.timeIntervalSince1970 )
        {
            let backgroundView = UIView()
            backgroundView.backgroundColor = UIColor.red
            cell.backgroundView = backgroundView
        }
        
                
        return cell
    }
    
    
    func contextualDeleteAction(forRowAtIndexPath indexPath: IndexPath) -> UIContextualAction {
            let action = UIContextualAction(style: .destructive, title: "Delete") { (contextAction: UIContextualAction, sourceView: UIView, completionHandler: (Bool) -> Void) in
                print("Deleting")
                let p = self.products[indexPath.item]
            
                print(p.name)
                print(p.id)
                
                self.db.deleteByID(id: p.id)
                self.products.remove(at: indexPath.item)
                //self.data.remove(at: indexPath.row)
                self.productTable.deleteRows(at: [indexPath], with: .left)
                completionHandler(true)
            }

            return action
        }
    
    
    func tableView(_ tableView: UITableView,
      editActionsForRowAt indexPath: IndexPath)
      -> [UITableViewRowAction]? {

      let deleteTitle = NSLocalizedString("Delete", comment: "Delete action")
      let deleteAction = UITableViewRowAction(style: .destructive,
        title: deleteTitle) { (action, indexPath) in
        //self.products.delete(at: indexPath)
        print("Delete!!!")
        print(indexPath)
        let p = self.products[indexPath.item]
    
        print(p.name)
        print(p.id)
        
        var notifyIdentifiers = [String]()
        notifyIdentifiers.append(p.expirationNotificationId)
        notifyIdentifiers.append(p.warningNotificationId)
        
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: notifyIdentifiers)
        self.db.deleteByID(id: p.id)
        self.products.remove(at: indexPath.item)
        self.productTable.deleteRows(at: [indexPath], with: .left)
      }
      return [deleteAction]
    }

    
    
    func requestNotificationPermission()
    {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound])
        { success, error in
            if success
            {
                print("All set!")
            } else if let error = error {
                print(error.localizedDescription)
            }
        }
    }

    
    private func addProductInfo(name: String, expirationDate: Date)
    {
        let warningNotificationId = addNotificationWarning(message: name, date: expirationDate)
        let expirationNotificationId = addExpirationNotification(message: name, date: expirationDate)
        
        db.insert(name: name, expirationDate: expirationDate as NSDate, warningNotificationId: warningNotificationId, expirationNotificationId: expirationNotificationId)
    }
    
    
    private func addNotificationWarning(message:String, date: Date) -> String
    {
        let title = "Expiration Warning"
        return addNotification(message: message, title: title, date: date);
    }
    
    private func addExpirationNotification(message:String, date: Date) -> String
    {
        let title = "Expired"
        return addNotification(message: message, title: title, date: date);
    }
    
    
    private func addNotification(message: String, title: String, date: Date) -> String
    {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM-dd-yyyy"
        let stringDate: String = dateFormatter.string(from: date as Date)
        
        
        let calendar = NSCalendar.init(calendarIdentifier: NSCalendar.Identifier.gregorian)
        
        
        let content = UNMutableNotificationContent()
        content.title = title + stringDate
        content.subtitle = message
        content.sound = UNNotificationSound.default
        
        var dateCompo = DateComponents()
        dateCompo.day = (calendar?.component(NSCalendar.Unit.day, from: date))!
        dateCompo.month = (calendar?.component(NSCalendar.Unit.month, from: date))!
        dateCompo.year = (calendar?.component(NSCalendar.Unit.year, from: date))!
        dateCompo.hour = 8
        dateCompo.minute = 0
        

        
        let trigger = UNCalendarNotificationTrigger.init(dateMatching: dateCompo, repeats: true)

        // choose a random identifier
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        
        

        print("sendNotification add notification")
        // add our notification request
        UNUserNotificationCenter.current().add(request)
        
        return request.identifier
        
    }



}


