//
//  ViewController.swift
//  QRScanner
//
//  Created by 송우진 on 12/10/24.
//

import UIKit
import AVFoundation

class ViewController: UIViewController {
    // 카메라 캡처 세션
    var captureSession: AVCaptureSession = .init()
    var previewLayer: AVCaptureVideoPreviewLayer = .init()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        view.backgroundColor = .black
        setupCaptureDevice()
    
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if captureSession.isRunning {
            captureSession.stopRunning()
        }
    }
    
    // 메모리 해제 시 세션 종료
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        captureSession = .init()
    }
    
    // 상태 표시줄 숨김
    override var prefersStatusBarHidden: Bool {
        true
    }
    
    // 세로 방향만 허용
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        .portrait
    }
}

extension ViewController {
    // QR 코드 스캔 시작
    func startRunning() {
        DispatchQueue.global(qos: .background).async {
            self.captureSession.startRunning()
        }
    }
    
    // 카메라 입력 장치 설정
    func setupCaptureDevice() {
        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else {
            print("카메라를 사용할 수 없습니다.")
            return
        }
        
        let videoInput: AVCaptureDeviceInput
        do {
            videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
        } catch {
            print("카메라 입력 장치 오류: \(error)")
            return
        }
        if (captureSession.canAddInput(videoInput)) {
            captureSession.addInput(videoInput)
        } else {
            print("입력을 추가할 수 없습니다.")
            return
        }
        
        // 메타데이터 출력 설정
        let metadataOutput = AVCaptureMetadataOutput()
        if (captureSession.canAddOutput(metadataOutput)) {
            captureSession.addOutput(metadataOutput)
            
            metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            metadataOutput.metadataObjectTypes = [.qr]
        } else {
            print("출력을 추가할 수 없습니다.")
            return
        }
        
        // 미리보기 레이어 설정
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.frame = view.layer.bounds
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)
        
        startRunning()
        
    }
}


extension ViewController: AVCaptureMetadataOutputObjectsDelegate {
    // QR 코드 인식 결과 처리
    func metadataOutput(
        _ output: AVCaptureMetadataOutput,
        didOutput metadataObjects: [AVMetadataObject],
        from connection: AVCaptureConnection
    ) {
        if let metadataObject = metadataObjects.first {
            guard let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject else { return }
            guard let stringValue = readableObject.stringValue else { return }
            AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
            found(code: stringValue)
        }
    }
    
    // QR 코드 인식 후 동작
    func found(code: String) {
        print("QR 코드 데이터: \(code)")
        captureSession.stopRunning()
        
        let alert = UIAlertController(title: "QR 코드 스캔 성공", message: code, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .default) { [weak self] _ in
            self?.startRunning()
        })
        present(alert, animated: true)
    }
}
