Expiration Date Monitor

Problem Description
People buy groceries with a range of expiration dates. The food is stored in the refrigerator or pantry and are often forgotten until after they had expired. Once expired, the food is thrown to the garbage. This causes an enormous amount of food waste and can make an unnecessary dent in a familys’ budget.
 Project solution 
One solution to save money and avoid food waste is to use an edge-based device, in this case an iPhone app, that warns people as food expires, providing an opportunity to consume the food before expiration. The app needs to be user friendly and able store data in a quick manner. The Expiration Date Monitor uses computer vision capabilities to identify expiration dates using text detection, and barcode decoding to identify product names and store data quick and seamlessly. As an add-on, once the data is stored, the user is notified before a specific food is about to expire, reminding the user to consume the food before it is too late.
Application Architecture
The application is written in Swift and targeting iPhones. The application has a main view controller which embeds a table that shows all the foods that were added to the app in ascending order based on their expiration dates. The table includes the product name and its expiration date, and have one of three background colors – red, yellow, white. Red denotes an expired food item, yellow denotes the food will expire in a day or two, and white denotes that the food will expire in two or more days. Notifications will appear on the iPhone for items that are about to expire. Users are also able to delete items once they are consumed.
All food items and expiration dates are stored on a local sqlite database. The sqlite database is a light database that is often used on endpoints, and would be sufficient to the minimal needs of the database in the app. 
To add a food item, a new view controller pops-up. The new view controller uses the phone’s camera to identify text using Apple’s Vision API VNRecognizeTextRequest class. The VNRecognizeTextRequest class detects and recognizes regions of text in an image. Once the app recognizes a text, the text is passed on to a filter mechanism that, using regular expression, detects different expiration date patterns (mm-dd-yyyy, ddMMMyy, etc.).
Another view controller is used to detect the product from it barcode. In this view controller, the app uses Apple’s Vision API VNDetectBarcodeRequest class, which creates an image analysis that finds and recognizes barcodes in an image. Here, the user uses the camera to capture a barcode image, which is translated to the product UPC number. The app gets the product name by sending a REST request to https://api.upcitemdb.com, and parsing its JSON reply.
Once the product name and the expiration date are captured, the app adds the data to the database, shows the added information in the main table, and sets up notifications.
Future Work
Currently, the application supports only three expiration dates patterns. Ideally, additional patterns can be added to support more expiration dates. The code is architected in a way that adding more patterns is an easy task.
The error handling is sufficient, however, to improve application resiliency, more error handling would be needed.
Code Reference
https://github.com/serez/MSDS462/tree/main/ExpirationDateMonitor

