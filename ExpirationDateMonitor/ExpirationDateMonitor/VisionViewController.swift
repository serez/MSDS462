/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Vision view controller.
			Recognizes text using a Vision VNRecognizeTextRequest request handler in pixel buffers from an AVCaptureOutput.
			Displays bounding boxes around recognized text results in real time.
*/

import Foundation
import UIKit
import AVFoundation
import Vision

class VisionViewController: ExpirationDateViewController {
    enum ExpDateVariations
    {
        case DatemmddYY
        case DateddMMMYY
        case DateMMMddYY
    }
    
	var request: VNRecognizeTextRequest!
	// Temporal string tracker
	let numberTracker = StringTracker()
    
    var expDates: [ExpDateVariations] = []
    
    
    
	
    override func viewDidLoad() {
		// Set up vision request before letting ViewController set up the camera
		// so that it exists when the first buffer is received.
		request = VNRecognizeTextRequest(completionHandler: recognizeTextHandler)

		super.viewDidLoad()
        
        expDates.append(ExpDateVariations.DatemmddYY)
        expDates.append(ExpDateVariations.DateddMMMYY)
        expDates.append(ExpDateVariations.DateMMMddYY)
	}
	
	//  Text recognition
	
	// Vision recognition handler.
	func recognizeTextHandler(request: VNRequest, error: Error?) {
		var expDates = [String]()
		var redBoxes = [CGRect]() // Shows all recognized text lines
		var greenBoxes = [CGRect]() // Shows words that might be serials
		
		guard let results = request.results as? [VNRecognizedTextObservation] else {
			return
		}
		
		let maximumCandidates = 1
		
		for visionResult in results {
			guard let candidate = visionResult.topCandidates(maximumCandidates).first else { continue }
			
			// Draw red boxes around any detected text, and green boxes around
			// any detected phone numbers. The phone number may be a substring
			// of the visionResult. If a substring, draw a green box around the
			// number and a red box around the full string. If the number covers
			// the full result only draw the green box.
			var numberIsSubstring = true
			
			//if let result = candidate.string.extractExpirationDate() {
            if let result = extractExpirationDate(data: candidate.string) {
                let (range, expDateAsString, expDate) = result
				// Number may not cover full visionResult. Extract bounding box
				// of substring.
				if let box = try? candidate.boundingBox(for: range)?.boundingBox {
                    expDates.append(expDateAsString)
					greenBoxes.append(box)
					numberIsSubstring = !(range.lowerBound == candidate.string.startIndex && range.upperBound == candidate.string.endIndex)
                    
                    self.expDate = expDate
				}
			}
			if numberIsSubstring {
				redBoxes.append(visionResult.boundingBox)
			}
		}
		
		// Log any found numbers.
		numberTracker.logFrame(strings: expDates)
		show(boxGroups: [(color: UIColor.red.cgColor, boxes: redBoxes), (color: UIColor.green.cgColor, boxes: greenBoxes)])
		
		// Check if we have any temporally stable numbers.
		if let sureNumber = numberTracker.getStableString() {
			showString(string: sureNumber)
			numberTracker.reset(string: sureNumber)
		}
	}
    
    
    ///////
    
    
    func getDatePattern(expDateType: ExpDateVariations) -> DateRegex?
    {
        switch expDateType
        {
        case ExpDateVariations.DatemmddYY:
            return DatemmddYY()
        case ExpDateVariations.DateddMMMYY:
            return  DateddMMMYY()
        case ExpDateVariations.DateMMMddYY:
            return DateMMMddYY()
        
        }
        
    }
    
    
    func extractExpirationDate(data: String) -> (Range<String.Index>, String, Date)? {
        
      //  var dataParser = nil
        print(data)
        for expDate in self.expDates
        {
            
            let dateParser = getDatePattern(expDateType: expDate)
            if(dateParser == nil)
            {
                continue
            }
            
            let pattern = dateParser?.pattern
            
            //print("pattern: \(pattern)")
            
            let range = data.range(of: pattern!, options: .regularExpression, range: nil, locale: nil)
            
            if(range == nil)
            {
                continue
            }
            
    
 
            print("Found match!!!")
    
            // Potential expiration date found.
            let substring = String(data[range!])
            print("substring: \(substring)")
    
            let nsrange = NSRange(substring.startIndex..., in: substring)

            let matched = matches(for: pattern!, in: substring)
            print(matched)
    
            do {
                // Tokenize date.
                let regex = try NSRegularExpression(pattern: pattern!, options: [])
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
                        dateParser?.parseData(data: matchString, index: rangeInd)
                    }
                }
                else
                {
                    print("No match")
                }
            } catch {
                print("Error \(error) when creating pattern")
            }
    
            print("Date as a number \(dateParser?.getDate())")
            print("Date as a string \(dateParser?.getDateAsString())")
    
    
            let result = dateParser?.getDateAsString()
            let expTime = dateParser?.getDate()
    
            print("expTime = \(String(describing: expTime))")
    
            return (range, result, expTime) as? (Range<String.Index>, String, Date)
        }
        return nil
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
    //////
	
	override func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
		if let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) {
			// Configure for running in real-time.
            request.recognitionLevel = .accurate//.fast
			
			request.usesLanguageCorrection = true
			// Only run on the region of interest for maximum speed.
			request.regionOfInterest = regionOfInterest
			
			let requestHandler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: textOrientation, options: [:])
			do {
				try requestHandler.perform([request])
			} catch {
				print(error)
			}
		}
	}
	
	// MARK: - Bounding box drawing
	
	// Draw a box on screen. Must be called from main queue.
	var boxLayer = [CAShapeLayer]()
	func draw(rect: CGRect, color: CGColor) {
		let layer = CAShapeLayer()
		layer.opacity = 0.5
		layer.borderColor = color
		layer.borderWidth = 1
		layer.frame = rect
		boxLayer.append(layer)
		previewView.videoPreviewLayer.insertSublayer(layer, at: 1)
	}
	
	// Remove all drawn boxes. Must be called on main queue.
	func removeBoxes() {
		for layer in boxLayer {
			layer.removeFromSuperlayer()
		}
		boxLayer.removeAll()
	}
	
	typealias ColoredBoxGroup = (color: CGColor, boxes: [CGRect])
	
	// Draws groups of colored boxes.
	func show(boxGroups: [ColoredBoxGroup]) {
		DispatchQueue.main.async {
			let layer = self.previewView.videoPreviewLayer
			self.removeBoxes()
			for boxGroup in boxGroups {
				let color = boxGroup.color
				for box in boxGroup.boxes {
					let rect = layer.layerRectConverted(fromMetadataOutputRect: box.applying(self.visionToAVFTransform))
					self.draw(rect: rect, color: color)
				}
			}
		}
	}
}
