//
//  ViewController.swift
//  Vision-Sampler
//
//  Created by 間嶋大輔 on 2024/01/19.
//

import UIKit
import Vision
import AVFoundation

class DetectBarcodeViewController: UIViewController,AVCaptureVideoDataOutputSampleBufferDelegate {

    lazy var request:VNDetectBarcodesRequest =  {
        let request = VNDetectBarcodesRequest(completionHandler: requestCompletionHandler)
        return request
    }()
    private var captureSession: AVCaptureSession!
    var videoOutput:AVCaptureVideoDataOutput!
    var processing = false

    private var preview = UIView()
    private lazy var previewLayer: AVCaptureVideoPreviewLayer = {
        let layer = AVCaptureVideoPreviewLayer(session: self.captureSession)
        layer.frame = preview.bounds
        layer.videoGravity = .resizeAspect
        layer.connection?.videoOrientation = .portrait
        return layer
    }()
    private var qrCodeFrameView = UIView()
    var qrCodeLabel = UILabel()
    var videoRect = CGRect.zero
    

    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        setupVideo()
    }
    
    func setupVideo() {
        let captureDevice:AVCaptureDevice = AVCaptureDevice.default(for: .video)!
        do {
            let input = try AVCaptureDeviceInput(device: captureDevice)
            captureSession = AVCaptureSession()
            captureSession?.addInput(input)
            
            videoOutput = AVCaptureVideoDataOutput()
            
            let output = AVCaptureMetadataOutput()
            captureSession?.addOutput(videoOutput)
            let queue = DispatchQueue(label: "VideoQueue")

            videoOutput.setSampleBufferDelegate(self, queue: queue)
            
            preview.layer.addSublayer(previewLayer)
            preview.backgroundColor = .black

            let dimensions = CMVideoFormatDescriptionGetDimensions(captureDevice.activeFormat.formatDescription)
            let videoSize = CGSize(width: CGFloat(dimensions.width), height: CGFloat(dimensions.height))
            let videoSizeAspect = videoSize.width/videoSize.height
            let previewHeight = self.view.bounds.width * videoSizeAspect
            videoRect = CGRect(x: 0, y: (preview.bounds.height-previewHeight)/2, width: view.bounds.width, height: previewHeight)

            queue.async {
                self.captureSession?.startRunning()
            }
        } catch {
            print("Error setting up capture session: \(error.localizedDescription)")
        }
    }
    
    func requestCompletionHandler(request:VNRequest?, error:Error?) {
        guard let observation = request?.results?.first as? VNBarcodeObservation else {
            barcodeNotDetected()
            return
        }
        
        barcodeDetected(observation: observation)
    }
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer),
              !processing else {return}
        processing = true
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer,orientation: .right, options: [:])
        do {
            try handler.perform([request])
        } catch {
            print("Vision error: \(error.localizedDescription)")
        }
    }
    
    func barcodeDetected(observation: VNBarcodeObservation) {
        processing = false
        if let stringValue = observation.payloadStringValue {
            print("QR Code Value: \(stringValue)")
            
            DispatchQueue.main.async {
                self.qrCodeLabel.isHidden = false
                self.qrCodeLabel.text = stringValue
            }
            let box = observation.boundingBox
            DispatchQueue.main.async { [self] in
                
                let invertBox = CGRect(x: box.minX, y: 1-box.maxY, width: box.width, height: box.height)
                var qrCodeFrame = VNImageRectForNormalizedRect(invertBox, Int(self.preview.bounds.width), Int(self.videoRect.height))
                qrCodeFrame = CGRect(x: qrCodeFrame.minX, y: qrCodeFrame.minY+videoRect.minY, width: qrCodeFrame.width, height: qrCodeFrame.height)
                print(qrCodeFrame)
                self.qrCodeLabel.isHidden = false
                self.qrCodeFrameView.isHidden = false
                self.qrCodeFrameView.frame = qrCodeFrame
                self.qrCodeLabel.frame = CGRect(x: self.qrCodeFrameView.frame.minX, y: self.qrCodeFrameView.frame.minY-40, width: 300, height: 40)
            }
        }
    }
    
    func barcodeNotDetected() {
        processing = false
        DispatchQueue.main.async {
            self.qrCodeFrameView.isHidden = true
            self.qrCodeLabel.isHidden = true
        }
    }
    
    func setupView() {
        view.addSubview(preview)
        preview.frame = view.bounds
        qrCodeFrameView.layer.borderColor = UIColor.red.cgColor
        qrCodeFrameView.layer.borderWidth = 2
        view.addSubview(qrCodeFrameView)
        view.bringSubviewToFront(qrCodeFrameView)
        qrCodeFrameView.isHidden = true
        view.addSubview(qrCodeLabel)
        qrCodeLabel.textColor = .red
    }

}

