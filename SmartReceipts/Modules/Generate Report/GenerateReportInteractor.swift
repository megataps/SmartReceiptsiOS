//
//  GenerateReportInteractor.swift
//  SmartReceipts
//
//  Created by Bogdan Evsenev on 07/06/2017.
//  Copyright © 2017 Will Baumann. All rights reserved.
//

import Foundation
import Viperit
import RxSwift
import RxCocoa
import Toaster
import MessageUI

class GenerateReportInteractor: Interactor {
    var generator: ReportAssetsGenerator?
    var shareService: GenerateReportShareService?
    var trip: WBTrip!
    
    private var fullPdfReport: BehaviorRelay         = BehaviorRelay(value: false)
    private var pdfReportWithoutTable: BehaviorRelay = BehaviorRelay(value: false)
    private var csvFile: BehaviorRelay               = BehaviorRelay(value: false)
    private var zipStampedJPGs: BehaviorRelay        = BehaviorRelay(value: false)
    
    private let bag = DisposeBag()
    
    var titleSubtitle: TitleSubtitle {
        return (trip.name, trip.formattedPrice())
    }
    
    func configure(with trip: WBTrip) {
        self.trip = trip
        generator = ReportAssetsGenerator(trip: trip)
        shareService = GenerateReportShareService(presenter: presenter, trip: trip)
    }
    
    func configureBinding() {
        presenter.fullPdfReport.bind(to: fullPdfReport).disposed(by: bag)
        presenter.pdfReportWithoutTable.bind(to: pdfReportWithoutTable).disposed(by: bag)
        presenter.csvFile.bind(to: csvFile).disposed(by: bag)
        presenter.zipStampedJPGs.bind(to: zipStampedJPGs).disposed(by: bag)
    }
    
    func trackConfigureReportEvent() {
        AnalyticsManager.sharedManager.record(event: Event.Informational.ConfigureReport)
    }
    
    func trackGeneratorEvents() {
        if fullPdfReport.value {
            AnalyticsManager.sharedManager.record(event: Event.Generate.FullPdfReport)
        }
        if pdfReportWithoutTable.value {
            AnalyticsManager.sharedManager.record(event: Event.Generate.ImagesPdfReport)
        }
        if csvFile.value {
            AnalyticsManager.sharedManager.record(event: Event.Generate.CsvReport)
        }
        if zipStampedJPGs.value {
            AnalyticsManager.sharedManager.record(event: Event.Generate.StampedZipReport)
        }
    }
    
    func generateReport() {
        if needEnableDistance() {
            Logger.debug("Empty Receipts and disabled Include Distances. Go to Settings")
            AnalyticsManager.sharedManager.record(event: Event.Generate.NothingToGenerateCSV)
            
            Toast.show(LocalizedString("generate_report_toast_csv_report_distances"))
            presenter.hideHudFromView()
            presenter.presentEnableDistances()
            return
        }
        
        if !validateSelection() {
            presenter.hideHudFromView()
            return
        }
        
        delayedExecution(DEFAULT_ANIMATION_DURATION) {
            
            self.generator?.setGenerated(self.fullPdfReport.value, imagesPDF: self.pdfReportWithoutTable.value,
                                          csv: self.csvFile.value, imagesZip: self.zipStampedJPGs.value)
            
            self.generator!.generate(onSuccessHandler: { (files) in
                TooltipService.shared.markReportGenerated()
                self.presenter.hideHudFromView()
                
                if !MFMailComposeViewController.canSendMail() {
                    self.shareService?.shareFiles(files)
                    Logger.debug("Mail app not configured on this device")
                    return
                }
                
                var actions = [UIAlertAction]()
                let message = LocalizedString("generate_report_share_method_sheet_title")
                
                let emailAction = UIAlertAction(title: LocalizedString("generate_report_share_method_email"), style: .default) { _ in
                    self.shareService?.emailFiles(files)
                }
                
                let otherAction = UIAlertAction(title: LocalizedString("generate_report_share_method_other"), style: .default) { _ in
                    self.shareService?.shareFiles(files)
                }
                
                actions.append(emailAction)
                actions.append(otherAction)
                actions.append(UIAlertAction(title: LocalizedString("DIALOG_CANCEL"), style: .cancel, handler: { _ in
                    for file in files { FileManager.deleteIfExists(filepath: file) }
                }))
                
                self.presenter.presentSheet(title: nil, message: message, actions: actions)
                
            }, onErrorHandler: { (error) in
                self.presenter.hideHudFromView()
                
                Logger.warning("ReportAssetsGenerator.generate() onError: \(error)")
                
                var actions = [UIAlertAction]()
                var title = LocalizedString("report_pdf_generation_error")
                var message = ""
                
                switch error {
                case .fullPdfFailed:
                    message = LocalizedString("DIALOG_EMAIL_CHECKBOX_PDF_FULL")
                case .fullPdfTooManyColumns:
                    title = LocalizedString("report_pdf_error_too_many_columns_title")
                    if WBPreferences.printReceiptTableLandscape() {
                        message = LocalizedString("report_pdf_error_too_many_columns_message")
                    } else {
                        message = LocalizedString("report_pdf_error_too_many_columns_message_landscape")
                    }
                    
                    let openSettingsAction = UIAlertAction(title: LocalizedString("report_pdf_error_go_to_settings"), style: .default, handler: { _ in
                        self.presenter.presentOutputSettings()
                    })
                    actions.append(openSettingsAction)
                    
                case .imagesPdf:
                    message = LocalizedString("DIALOG_EMAIL_CHECKBOX_PDF_IMAGES")
                case .csvFailed:
                    message = LocalizedString("DIALOG_EMAIL_CHECKBOX_CSV")
                case .zipImagesFailed:
                    message = LocalizedString("DIALOG_EMAIL_CHECKBOX_ZIP_WITH_METADATA")
                }
                actions.append(UIAlertAction(title: LocalizedString("generic_button_title_ok"), style: .default, handler: nil))
                self.presenter.presentSheet(title: title, message: message, actions: actions)
            })
        }
    }
    
    func validateSelection() -> Bool {
        if (!fullPdfReport.value && !pdfReportWithoutTable.value && !csvFile.value && !zipStampedJPGs.value) {
            presenter.presentAlert(title: LocalizedString("generic_error_alert_title"),
                                   message: LocalizedString("DIALOG_EMAIL_TOAST_NO_SELECTION"))
            return false
        }
        return true
    }
    
    private func needEnableDistance() -> Bool {
        return csvFile.value && !WBPreferences.printDistanceTable() && Database.sharedInstance().allReceipts(for: trip).isEmpty
    }
    
}


// MARK: - VIPER COMPONENTS API (Auto-generated code)
private extension GenerateReportInteractor {
    var presenter: GenerateReportPresenter {
        return _presenter as! GenerateReportPresenter
    }
}
