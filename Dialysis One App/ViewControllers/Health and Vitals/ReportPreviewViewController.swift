//
//  ReportPreviewViewController.swift
//  Dialysis One App
//
//  Created by user@22 on 09/11/25.
//

import UIKit
import WebKit
import PDFKit

class ReportPreviewViewController: UIViewController {
    
    @IBOutlet weak var webView: WKWebView!
    
    var reportURL: URL?
    var reportTitle: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigationBar()
        loadPDF()
    }
    
    func setupNavigationBar() {
        title = reportTitle ?? "Report Preview"
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .action,
            target: self,
            action: #selector(shareTapped)
        )
    }
    
    func loadPDF() {
        guard let url = reportURL else { return }
        
        // Check if file exists
        guard FileManager.default.fileExists(atPath: url.path) else {
            showAlert(message: "File not found")
            return
        }
        
        // Load PDF in web view
        webView.loadFileURL(url, allowingReadAccessTo: url.deletingLastPathComponent())
    }
    
    @objc func shareTapped() {
        guard let url = reportURL else { return }
        let activityVC = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        present(activityVC, animated: true)
    }
    
    func showAlert(message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
