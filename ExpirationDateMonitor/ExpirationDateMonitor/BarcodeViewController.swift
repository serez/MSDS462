//
//  BarcodeViewController.swift
//  ExpirationDateMonitor
//
//  Created by Shachar Erez on 11/23/20.
//

import AVFoundation
import Vision
import UIKit

class BarcodeViewController: UIViewController, AVCapturePhotoCaptureDelegate, ProductInfoDelegate
{
    
    
    
    var captureSession: AVCaptureSession!
    var backCamera: AVCaptureDevice?
    var cameraPreviewLayer: AVCaptureVideoPreviewLayer?
    var captureOutput: AVCapturePhotoOutput?
    var delegate:ProductInfoDelegate?

    var shutterButton: UIButton!

    var brandCatalog = BrandCatalog()

    lazy var detectBarcodeRequest: VNDetectBarcodesRequest = {
        return VNDetectBarcodesRequest(completionHandler: { (request, error) in
            guard error == nil else {
                self.showAlert(withTitle: "Barcode Error", message: error!.localizedDescription, actionTitle: "OK")
                return
            }

            self.processClassification(for: request)
        })
    }()

    // MARK: - View controller life cycle
    override func viewDidLoad() {
        super.viewDidLoad()

        checkPermissions()
        setupCameraLiveView()
        addShutterButton()
    }
    
    func setExpirationDate(date: Date)
    {
    }
    
    func setProductName(name: String) {
        print(name)
    
    }
    
    func onProductInfoReady() {
        
    }

    @IBAction func onCancel(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    override func viewDidAppear(_ animated: Bool) {
        // Every time the user re-enters the app, we must be sure we have access to the camera.
        checkPermissions()
    }

    // MARK: - User interface
    override var prefersStatusBarHidden: Bool {
        return true
    }

    // MARK: - Camera
    private func checkPermissions() {
        let mediaType = AVMediaType.video
        let status = AVCaptureDevice.authorizationStatus(for: mediaType)

        switch status {
        case .denied, .restricted:
            displayNotAuthorizedUI()
        case.notDetermined:
            // Prompt the user for access.
            AVCaptureDevice.requestAccess(for: mediaType) { granted in
                guard granted != true else { return }

                // The UI must be updated on the main thread.
                DispatchQueue.main.async {
                    self.displayNotAuthorizedUI()
                }
            }

        default: break
        }
    }

    private func setupCameraLiveView() {
        // Set up the camera session.
        captureSession = AVCaptureSession()
        captureSession.sessionPreset = .hd1280x720

        // Set up the video device.
        let deviceDiscoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [AVCaptureDevice.DeviceType.builtInWideAngleCamera],
                                                                      mediaType: AVMediaType.video,
                                                                      position: .back)
        let devices = deviceDiscoverySession.devices
        for device in devices {
            if device.position == AVCaptureDevice.Position.back {
                backCamera = device
            }
        }

        // Make sure the actually is a back camera on this particular iPhone.
        guard let backCamera = backCamera else {
            showAlert(withTitle: "Camera error", message: "There seems to be no camera on your device.", actionTitle: "OK")
            return
        }

        // Set up the input and output stream.
        do {
            let captureDeviceInput = try AVCaptureDeviceInput(device: backCamera)
            captureSession.addInput(captureDeviceInput)
        } catch {
            showAlert(withTitle: "Camera error", message: "Your camera can't be used as an input device.", actionTitle: "OK")
            return
        }

        // Initialize the capture output and add it to the session.
        captureOutput = AVCapturePhotoOutput()
        captureOutput!.setPreparedPhotoSettingsArray([AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.jpeg])], completionHandler: nil)
        captureSession.addOutput(captureOutput!)

        // Add a preview layer.
        cameraPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        cameraPreviewLayer!.videoGravity = .resizeAspectFill
        cameraPreviewLayer!.connection?.videoOrientation = .portrait
        cameraPreviewLayer?.frame = view.frame

        self.view.layer.insertSublayer(cameraPreviewLayer!, at: 0)

        // Start the capture session.
        captureSession.startRunning()
    }

    @objc func captureImage() {
        let settings = AVCapturePhotoSettings()
        captureOutput?.capturePhoto(with: settings, delegate: self)
    }

    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let imageData = photo.fileDataRepresentation(),
            let image = UIImage(data: imageData) {

            // Convert image to CIImage.
            guard let ciImage = CIImage(image: image) else {
                fatalError("Unable to create \(CIImage.self) from \(image).")
            }

            // Perform the classification request on a background thread.
            DispatchQueue.global(qos: .userInitiated).async {
                let handler = VNImageRequestHandler(ciImage: ciImage, orientation: CGImagePropertyOrientation.up, options: [:])

                do {
                    try handler.perform([self.detectBarcodeRequest])
                } catch {
                    self.showAlert(withTitle: "Error Decoding Barcode", message: error.localizedDescription, actionTitle: "Try Again")
                }
            }
        }
    }

    // MARK: - User interface
    private func displayNotAuthorizedUI() {
        let label = UILabel(frame: CGRect(x: 0, y: 0, width: view.frame.width * 0.8, height: 20))
        label.textAlignment = .center
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        label.text = "Please grant access to the camera for scanning barcodes."
        label.sizeToFit()

        let button = UIButton(frame: CGRect(x: 0, y: label.frame.height + 8, width: view.frame.width * 0.8, height: 35))
        button.layer.cornerRadius = 10
        button.setTitle("Grant Access", for: .normal)
        button.backgroundColor = UIColor(displayP3Red: 4.0/255.0, green: 92.0/255.0, blue: 198.0/255.0, alpha: 1)
        button.setTitleColor(.white, for: .normal)
        button.addTarget(self, action: #selector(openSettings), for: .touchUpInside)

        let containerView = UIView(frame: CGRect(
            x: view.frame.width * 0.1,
            y: (view.frame.height - label.frame.height + 8 + button.frame.height) / 2,
            width: view.frame.width * 0.8,
            height: label.frame.height + 8 + button.frame.height
            )
        )
        containerView.addSubview(label)
        containerView.addSubview(button)
        view.addSubview(containerView)
    }

    private func addShutterButton() {
        let width: CGFloat = 75
        let height = width
        shutterButton = UIButton(frame: CGRect(x: (view.frame.width - width) / 2,
                                               y: view.frame.height - height - 32,
                                               width: width,
                                               height: height
            )
        )
        shutterButton.layer.cornerRadius = width / 2
        shutterButton.backgroundColor = UIColor.init(displayP3Red: 1, green: 1, blue: 1, alpha: 0.8)
        shutterButton.showsTouchWhenHighlighted = true
        shutterButton.addTarget(self, action: #selector(captureImage), for: .touchUpInside)
        view.addSubview(shutterButton)
    }

   private func showInfo(for payload: String) {
        if let brand = brandCatalog.item(forKey: payload) {
            print(payload)
            showAlert(withTitle: brand.name ?? "No product name provided", message: payload, actionTitle: "Done")
        } else {
            showAlert(withTitle: "", message: payload, actionTitle: "Done")
        }
    }

    // MARK: - Vision
    func processClassification(for request: VNRequest) {
        DispatchQueue.main.async {
            print(request)
            if let bestResult = request.results?.first as? VNBarcodeObservation,
                let payload = bestResult.payloadStringValue {
                self.parseJson(upc: payload)
               // self.showInfo(for: payload)
            } else {
                self.showAlert(withTitle: "Unable to extract results",
                               message: "Cannot extract barcode information from data.", actionTitle: "Try Again")
            }
        }
    }
    
    
    func parseJson(upc: String)
    {
        let url = URL(string: "https://api.upcitemdb.com/prod/trial/lookup?upc=" + upc)
        guard let requestUrl = url else { fatalError() }
        // Create URL Request
        var request = URLRequest(url: requestUrl)
        // Specify HTTP Method to use
        request.httpMethod = "GET"
        // Send HTTP Request
        let task = URLSession.shared.dataTask(with: request)
        {
            (data, response, error) in
       
            if let httpResponse = response as? HTTPURLResponse {
                    print(httpResponse.statusCode)
                }
            guard error == nil else {
                let errMessage = "Error calling upc mdb"
                print(errMessage)
                print(error!)
                DispatchQueue.main.async
                {
                    self.showAlert(withTitle: "Unable to extract results",message: errMessage, actionTitle: "OK")
                }
                return
              }
            
            guard let data = data else { return }
            
            if let returnData = String(data: data, encoding: .utf8) {
                      print(returnData)
                    } else {
                      print("Faile to convert data to string")
                    }
            
            // Using parseJSON() function to convert data to Swift struct
            let todoItem = self.parseJSON(data: data)
                    
            // Read todo item title
            guard let todoItemModel = todoItem else { return }
            var productInfo = ""
            if(todoItemModel.items.count > 0)
            {
                print("Todo item title = \(todoItemModel.items[0].title)")
                productInfo = todoItemModel.items[0].brand + " " + todoItemModel.items[0].title //+ " (" + upc + ")"
            }
            else
            {
                productInfo = upc
            }
            
            DispatchQueue.main.async
            {
                self.handleProductInfo(productInfo: productInfo)
               // self.showInfo(for: productInfo)
            }
           
           
            
        }
        task.resume()
    }
    
    
    func handleProductInfo(productInfo: String)
    {
        let alertController = UIAlertController(title: "Product Info", message: productInfo, preferredStyle: .alert)
     
        alertController.addAction(UIAlertAction(title: "Done", style: .default, handler: {_ in self.sendDataToMainController(productInfo: productInfo)}))
        present(alertController, animated: true)
        
       
    }
    
    func sendDataToMainController(productInfo: String)
    {
        let vc = UIApplication.shared.windows.first!.rootViewController as! ViewController
        self.delegate = vc
        
        let expiration_vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "Expiration_Date_vc") as! VisionViewController
        
        delegate?.setProductName(name: productInfo)
        delegate?.onProductInfoReady()
        
        self.view.window?.rootViewController?.dismiss(animated: true, completion: nil)
        
      //  expiration_vc.dismiss(animated: true, completion: nil)
     //   self.dismiss(animated: true, completion: nil)
        
    }
    
    
    func parseJSON(data: Data) -> BarcodeReply?
    {
        print(data)
        var returnValue: BarcodeReply?
        do {
            returnValue = try JSONDecoder().decode(BarcodeReply.self, from: data)
        } catch {
            
            print("Error took place - \(error.localizedDescription).")
        }
        
        return returnValue
    }
    
    
 
    
    // MARK: - Helper functions
    @objc private func openSettings() {
        let settingsURL = URL(string: UIApplication.openSettingsURLString)!
        UIApplication.shared.open(settingsURL) { _ in
            self.checkPermissions()
        }
    }

    private func showAlert(withTitle title: String, message: String, actionTitle: String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        print("title: \(title)")
        print("message: \(message)")
        alertController.addAction(UIAlertAction(title: actionTitle, style: .default))
        present(alertController, animated: true)
    }
    
    
    
   
}


struct BarcodeReply: Codable
{
    let code: String
    let total: Int
    let offset: Int
    let items: [BarcodeItem]
}


struct BarCodeOffer: Codable
{
    let merchant: String
    let domain: String
    let title: String
    let currency: String
    //let list_price: Float
    let price: Float
    let shipping: String
    let condition: String
    let availability: String
    let link: URL
    let updated_t: ULONG
}

struct BarcodeItem: Codable
{
    let ean: String
    let title: String
    let upc: String?
    let gtin: String?
    let elid: String?
    let description: String
    let brand: String
    let model: String
    let color: String
    let size: String
    let dimension: String
    let weight: String
    let category: String
    let currency: String
    let lowest_recorded_price: Float?
    let highest_recorded_price: Float?
    let images: [URL]
    let offers: [BarCodeOffer]
    let asin: String?
    let user_dat: String?
}
