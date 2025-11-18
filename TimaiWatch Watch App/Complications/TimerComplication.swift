//
//  TimerComplication.swift
//  TimaiWatch
//
//  Copyright (c) 2025 Dr. Thomas Entner.
//  All rights reserved.
//
//  Licensed under the Business Source License 1.1.
//  Usage is free for non-commercial and personal use.
//  Commercial use requires a commercial license.
//
import ClockKit
import UIKit

/// Complication Controller for Watch Face
class TimerComplicationController: NSObject, CLKComplicationDataSource {
    
    // MARK: - Complication Configuration
    
    func getComplicationDescriptors(handler: @escaping ([CLKComplicationDescriptor]) -> Void) {
        let descriptors = [
            CLKComplicationDescriptor(
                identifier: "TimerComplication",
                displayName: "watch.complication.name".localized(),
                supportedFamilies: CLKComplicationFamily.allCases
            )
        ]
        handler(descriptors)
    }
    
    // MARK: - Timeline Configuration
    
    func getTimelineStartDate(for complication: CLKComplication, withHandler handler: @escaping (Date?) -> Void) {
        handler(Date())
    }
    
    func getTimelineEndDate(for complication: CLKComplication, withHandler handler: @escaping (Date?) -> Void) {
        // Update for 24 hours
        handler(Date().addingTimeInterval(24 * 60 * 60))
    }
    
    func getPrivacyBehavior(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationPrivacyBehavior) -> Void) {
        handler(.showOnLockScreen)
    }
    
    // MARK: - Timeline Population
    
    func getCurrentTimelineEntry(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationTimelineEntry?) -> Void) {
        let timer = WatchConnectivityService.shared.currentTimer
        let template = getTemplate(for: complication, timer: timer)
        let entry = CLKComplicationTimelineEntry(date: Date(), complicationTemplate: template)
        handler(entry)
    }
    
    func getTimelineEntries(for complication: CLKComplication, after date: Date, limit: Int, withHandler handler: @escaping ([CLKComplicationTimelineEntry]?) -> Void) {
        // Update every minute
        var entries: [CLKComplicationTimelineEntry] = []
        var currentDate = date
        
        for _ in 0..<limit {
            let timer = WatchConnectivityService.shared.currentTimer
            let template = getTemplate(for: complication, timer: timer)
            let entry = CLKComplicationTimelineEntry(date: currentDate, complicationTemplate: template)
            entries.append(entry)
            currentDate = Calendar.current.date(byAdding: .minute, value: 1, to: currentDate)!
        }
        
        handler(entries)
    }
    
    // MARK: - Sample Templates
    
    func getLocalizableSampleTemplate(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationTemplate?) -> Void) {
        let sampleTimer = ActiveTimer(
            timesheetId: 1,
            projectId: 1,
            projectName: "Projekt",
            activityId: 1,
            activityName: "Aktivität",
            customerId: 1,
            customerName: "Kunde",
            startDate: Date().addingTimeInterval(-3600),
            description: nil
        )
        let template = getTemplate(for: complication, timer: sampleTimer)
        handler(template)
    }
    
    // MARK: - Template Creation
    
    private func getTemplate(for complication: CLKComplication, timer: ActiveTimer?) -> CLKComplicationTemplate {
        switch complication.family {
        case .modularSmall:
            return createModularSmallTemplate(timer: timer)
        case .modularLarge:
            return createModularLargeTemplate(timer: timer)
        case .utilitarianSmall:
            return createUtilitarianSmallTemplate(timer: timer)
        case .utilitarianSmallFlat:
            return createUtilitarianSmallFlatTemplate(timer: timer)
        case .utilitarianLarge:
            return createUtilitarianLargeTemplate(timer: timer)
        case .circularSmall:
            return createCircularSmallTemplate(timer: timer)
        case .extraLarge:
            return createExtraLargeTemplate(timer: timer)
        case .graphicCorner:
            return createGraphicCornerTemplate(timer: timer)
        case .graphicBezel:
            return createGraphicBezelTemplate(timer: timer)
        case .graphicCircular:
            return createGraphicCircularTemplate(timer: timer)
        case .graphicRectangular:
            return createGraphicRectangularTemplate(timer: timer)
        case .graphicExtraLarge:
            return createGraphicExtraLargeTemplate(timer: timer)
        @unknown default:
            return createModularSmallTemplate(timer: timer)
        }
    }
    
    private func createModularSmallTemplate(timer: ActiveTimer?) -> CLKComplicationTemplate {
        if let timer = timer {
            let template = CLKComplicationTemplateModularSmallSimpleText(textProvider: CLKSimpleTextProvider(text: timer.formattedElapsedTime.components(separatedBy: ":").prefix(2).joined(separator: ":")))
            return template
        } else {
            let template = CLKComplicationTemplateModularSmallSimpleImage(imageProvider: CLKImageProvider(onePieceImage: UIImage(systemName: "timer")!))
            return template
        }
    }
    
    private func createModularLargeTemplate(timer: ActiveTimer?) -> CLKComplicationTemplate {
        if let timer = timer {
            let template = CLKComplicationTemplateModularLargeStandardBody(
                headerTextProvider: CLKSimpleTextProvider(text: timer.projectName),
                body1TextProvider: CLKSimpleTextProvider(text: timer.formattedElapsedTime),
                body2TextProvider: CLKSimpleTextProvider(text: timer.activityName)
            )
            return template
        } else {
            let template = CLKComplicationTemplateModularLargeStandardBody(
                headerTextProvider: CLKSimpleTextProvider(text: "watch.complication.name".localized()),
                body1TextProvider: CLKSimpleTextProvider(text: "watch.complication.noTimer".localized())
            )
            return template
        }
    }
    
    private func createUtilitarianSmallTemplate(timer: ActiveTimer?) -> CLKComplicationTemplate {
        if let timer = timer {
            let template = CLKComplicationTemplateUtilitarianSmallFlat(textProvider: CLKSimpleTextProvider(text: timer.formattedElapsedTime.components(separatedBy: ":").prefix(2).joined(separator: ":")))
            return template
        } else {
            let template = CLKComplicationTemplateUtilitarianSmallFlat(textProvider: CLKSimpleTextProvider(text: "⏱"))
            return template
        }
    }
    
    private func createUtilitarianSmallFlatTemplate(timer: ActiveTimer?) -> CLKComplicationTemplate {
        return createUtilitarianSmallTemplate(timer: timer)
    }
    
    private func createUtilitarianLargeTemplate(timer: ActiveTimer?) -> CLKComplicationTemplate {
        if let timer = timer {
            let template = CLKComplicationTemplateUtilitarianLargeFlat(textProvider: CLKSimpleTextProvider(text: "\(timer.formattedElapsedTime) - \(timer.projectName)"))
            return template
        } else {
            let template = CLKComplicationTemplateUtilitarianLargeFlat(textProvider: CLKSimpleTextProvider(text: "watch.complication.name".localized()))
            return template
        }
    }
    
    private func createCircularSmallTemplate(timer: ActiveTimer?) -> CLKComplicationTemplate {
        if let timer = timer {
            let template = CLKComplicationTemplateCircularSmallSimpleText(textProvider: CLKSimpleTextProvider(text: timer.formattedElapsedTime.components(separatedBy: ":").prefix(2).joined(separator: ":")))
            return template
        } else {
            let template = CLKComplicationTemplateCircularSmallSimpleImage(imageProvider: CLKImageProvider(onePieceImage: UIImage(systemName: "timer")!))
            return template
        }
    }
    
    private func createExtraLargeTemplate(timer: ActiveTimer?) -> CLKComplicationTemplate {
        if let timer = timer {
            let template = CLKComplicationTemplateExtraLargeSimpleText(textProvider: CLKSimpleTextProvider(text: timer.formattedElapsedTime.components(separatedBy: ":").prefix(2).joined(separator: ":")))
            return template
        } else {
            let template = CLKComplicationTemplateExtraLargeSimpleImage(imageProvider: CLKImageProvider(onePieceImage: UIImage(systemName: "timer")!))
            return template
        }
    }
    
    private func createGraphicCornerTemplate(timer: ActiveTimer?) -> CLKComplicationTemplate {
        if let timer = timer {
            let template = CLKComplicationTemplateGraphicCornerTextImage(
                textProvider: CLKSimpleTextProvider(text: timer.formattedElapsedTime),
                imageProvider: CLKFullColorImageProvider(fullColorImage: UIImage(systemName: "timer")!)
            )
            return template
        } else {
            let template = CLKComplicationTemplateGraphicCornerTextImage(
                textProvider: CLKSimpleTextProvider(text: "watch.complication.name".localized()),
                imageProvider: CLKFullColorImageProvider(fullColorImage: UIImage(systemName: "timer")!)
            )
            return template
        }
    }
    
    private func createGraphicBezelTemplate(timer: ActiveTimer?) -> CLKComplicationTemplate {
        let circularTemplate = createGraphicCircularTemplate(timer: timer) as! CLKComplicationTemplateGraphicCircular
        if let timer = timer {
            let template = CLKComplicationTemplateGraphicBezelCircularText(
                circularTemplate: circularTemplate,
                textProvider: CLKSimpleTextProvider(text: timer.projectName)
            )
            return template
        } else {
            let template = CLKComplicationTemplateGraphicBezelCircularText(
                circularTemplate: circularTemplate,
                textProvider: CLKSimpleTextProvider(text: "watch.complication.name".localized())
            )
            return template
        }
    }
    
    private func createGraphicCircularTemplate(timer: ActiveTimer?) -> CLKComplicationTemplate {
        if let timer = timer {
            let template = CLKComplicationTemplateGraphicCircularStackImage(
                line1ImageProvider: CLKFullColorImageProvider(fullColorImage: UIImage(systemName: "timer")!),
                line2TextProvider: CLKSimpleTextProvider(text: timer.formattedElapsedTime.components(separatedBy: ":").prefix(2).joined(separator: ":"))
            )
            return template
        } else {
            let template = CLKComplicationTemplateGraphicCircularImage(
                imageProvider: CLKFullColorImageProvider(fullColorImage: UIImage(systemName: "timer")!)
            )
            return template
        }
    }
    
    private func createGraphicRectangularTemplate(timer: ActiveTimer?) -> CLKComplicationTemplate {
        if let timer = timer {
            let template = CLKComplicationTemplateGraphicRectangularStandardBody(
                headerTextProvider: CLKSimpleTextProvider(text: timer.projectName),
                body1TextProvider: CLKSimpleTextProvider(text: timer.formattedElapsedTime),
                body2TextProvider: CLKSimpleTextProvider(text: timer.activityName)
            )
            return template
        } else {
            let template = CLKComplicationTemplateGraphicRectangularStandardBody(
                headerTextProvider: CLKSimpleTextProvider(text: "watch.complication.name".localized()),
                body1TextProvider: CLKSimpleTextProvider(text: "watch.complication.noTimer".localized())
            )
            return template
        }
    }
    
    private func createGraphicExtraLargeTemplate(timer: ActiveTimer?) -> CLKComplicationTemplate {
        if let timer = timer {
            let template = CLKComplicationTemplateGraphicExtraLargeCircularStackImage(
                line1ImageProvider: CLKFullColorImageProvider(fullColorImage: UIImage(systemName: "timer")!),
                line2TextProvider: CLKSimpleTextProvider(text: timer.formattedElapsedTime.components(separatedBy: ":").prefix(2).joined(separator: ":"))
            )
            return template
        } else {
            let template = CLKComplicationTemplateGraphicExtraLargeCircularImage(
                imageProvider: CLKFullColorImageProvider(fullColorImage: UIImage(systemName: "timer")!)
            )
            return template
        }
    }
}

