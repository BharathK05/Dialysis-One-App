//
//  ReportPreviewViewController.swift
//  Dialysis One App
//
//  Created by user@22 on 18/11/25.
//

import UIKit
import PDFKit

class ReportPreviewViewController: UIViewController {
    private let pdfView = PDFView()
    var fileURL: URL?
    var reportTitle: String?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        navigationItem.title = reportTitle ?? "Preview"
        setupPDF()
        loadFile()
    }

    private func setupPDF() {
        pdfView.translatesAutoresizingMaskIntoConstraints = false
        pdfView.autoScales = true
        view.addSubview(pdfView)
        NSLayoutConstraint.activate([
            pdfView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            pdfView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            pdfView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            pdfView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func loadFile() {
        guard let u = fileURL else { return }
        if let doc = PDFDocument(url: u) {
            pdfView.document = doc
        } else {
            let lbl = UILabel()
            lbl.text = "Unable to open file"
            lbl.textAlignment = .center
            view.addSubview(lbl)
            lbl.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                lbl.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                lbl.centerYAnchor.constraint(equalTo: view.centerYAnchor)
            ])
        }
    }
}

