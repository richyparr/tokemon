import SwiftUI
import AppKit
import UniformTypeIdentifiers

/// Manages PDF and CSV export of usage data.
/// All methods are static and @MainActor for NSSavePanel access.
@MainActor
struct ExportManager {

    // MARK: - PDF Generation

    /// Generate a PDF from a SwiftUI view and save to a temporary file.
    /// - Parameters:
    ///   - reportView: The SwiftUI view to render as PDF.
    ///   - filename: Suggested filename for the temp file.
    /// - Returns: URL of the generated PDF temp file, or nil on failure.
    static func generatePDF(from reportView: some View, filename: String = "Tokemon-Report.pdf") -> URL? {
        let renderer = ImageRenderer(content: reportView)
        renderer.scale = 2.0 // Retina

        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(filename)

        // US Letter: 612 x 792 points (8.5 x 11 inches at 72 DPI)
        var box = CGRect(x: 0, y: 0, width: 612, height: 792)

        guard let context = CGContext(tempURL as CFURL, mediaBox: &box, nil) else {
            return nil
        }

        renderer.render { size, renderContent in
            // Start a PDF page
            context.beginPDFPage(nil)

            // Apply 36pt (0.5 inch) margins
            let marginX: CGFloat = 36
            let marginY: CGFloat = 36
            let availableWidth = box.width - (marginX * 2)
            let availableHeight = box.height - (marginY * 2)

            // Scale to fit within margins
            let scaleX = availableWidth / size.width
            let scaleY = availableHeight / size.height
            let scale = min(scaleX, scaleY, 1.0) // Don't scale up

            // Position at top-left with margins (PDF coordinate system: origin at bottom-left)
            let scaledHeight = size.height * scale
            context.translateBy(x: marginX, y: box.height - marginY - scaledHeight)
            context.scaleBy(x: scale, y: scale)

            renderContent(context)

            context.endPDFPage()
            context.closePDF()
        }

        return tempURL
    }

    // MARK: - Multi-Page PDF Generation

    /// Generate a multi-page PDF from an array of page views.
    /// - Parameters:
    ///   - pages: Array of AnyView pages to render.
    ///   - filename: Suggested filename for the temp file.
    /// - Returns: URL of the generated PDF temp file, or nil on failure.
    static func generateMultiPagePDF(pages: [AnyView], filename: String = "Tokemon-Report.pdf") -> URL? {
        guard !pages.isEmpty else { return nil }

        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(filename)

        // US Letter: 612 x 792 points (8.5 x 11 inches at 72 DPI)
        var box = CGRect(x: 0, y: 0, width: 612, height: 792)

        guard let context = CGContext(tempURL as CFURL, mediaBox: &box, nil) else {
            return nil
        }

        for page in pages {
            let renderer = ImageRenderer(content: page)
            renderer.scale = 2.0

            renderer.render { size, renderContent in
                context.beginPDFPage(nil)

                // Apply 36pt (0.5 inch) margins
                let marginX: CGFloat = 36
                let marginY: CGFloat = 36
                let availableWidth = box.width - (marginX * 2)
                let availableHeight = box.height - (marginY * 2)

                // Scale to fit within margins
                let scaleX = availableWidth / size.width
                let scaleY = availableHeight / size.height
                let scale = min(scaleX, scaleY, 1.0)

                // Position at top-left with margins
                let scaledHeight = size.height * scale
                context.translateBy(x: marginX, y: box.height - marginY - scaledHeight)
                context.scaleBy(x: scale, y: scale)

                renderContent(context)

                context.endPDFPage()
            }
        }

        context.closePDF()
        return tempURL
    }

    /// Show a save panel and export a multi-page PDF.
    /// - Parameters:
    ///   - pages: Array of AnyView pages to render.
    ///   - suggestedFilename: Default filename for the save dialog.
    /// - Returns: true if export succeeded, false otherwise.
    static func exportMultiPagePDF(pages: [AnyView], suggestedFilename: String) async -> Bool {
        NSApp.activate(ignoringOtherApps: true)

        let panel = NSSavePanel()
        panel.allowedContentTypes = [.pdf]
        panel.nameFieldStringValue = suggestedFilename
        panel.canCreateDirectories = true
        panel.title = "Export Usage Report"
        panel.prompt = "Export"

        let response = await panel.begin()
        guard response == .OK, let destinationURL = panel.url else {
            return false
        }

        guard let tempURL = generateMultiPagePDF(pages: pages, filename: suggestedFilename) else {
            return false
        }

        do {
            if FileManager.default.fileExists(atPath: destinationURL.path) {
                try FileManager.default.removeItem(at: destinationURL)
            }
            try FileManager.default.moveItem(at: tempURL, to: destinationURL)
            NSWorkspace.shared.activateFileViewerSelecting([destinationURL])
            return true
        } catch {
            try? FileManager.default.removeItem(at: tempURL)
            return false
        }
    }

    // MARK: - PDF Export

    /// Show a save panel and export a PDF report.
    /// - Parameters:
    ///   - reportView: The SwiftUI view to render as PDF.
    ///   - suggestedFilename: Default filename for the save dialog.
    /// - Returns: true if export succeeded, false otherwise.
    static func exportPDF(reportView: some View, suggestedFilename: String = "Tokemon-Report.pdf") async -> Bool {
        // Critical for LSUIElement apps: activate before showing save panel
        NSApp.activate(ignoringOtherApps: true)

        let panel = NSSavePanel()
        panel.allowedContentTypes = [.pdf]
        panel.nameFieldStringValue = suggestedFilename
        panel.canCreateDirectories = true
        panel.title = "Export Usage Report"
        panel.prompt = "Export"

        // Use standalone panel (not beginSheetModal -- no reliable key window in LSUIElement app)
        let response = await panel.begin()
        guard response == .OK, let destinationURL = panel.url else {
            return false
        }

        // Generate PDF to temp file
        guard let tempURL = generatePDF(from: reportView, filename: suggestedFilename) else {
            return false
        }

        do {
            // Remove existing file at destination if present
            if FileManager.default.fileExists(atPath: destinationURL.path) {
                try FileManager.default.removeItem(at: destinationURL)
            }
            try FileManager.default.moveItem(at: tempURL, to: destinationURL)

            // Reveal in Finder on success
            NSWorkspace.shared.activateFileViewerSelecting([destinationURL])
            return true
        } catch {
            // Clean up temp file on error
            try? FileManager.default.removeItem(at: tempURL)
            return false
        }
    }

    // MARK: - CSV Generation

    /// Generate a CSV string from usage data points.
    /// - Parameter points: Array of usage data points.
    /// - Returns: CSV-formatted string with header row and data rows.
    static func generateCSV(from points: [UsageDataPoint]) -> String {
        let header = "Timestamp,Utilization %,7-Day Utilization %,Source"

        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        let rows = points.map { point -> String in
            let timestamp = escapeCSVField(formatter.string(from: point.timestamp))
            let primary = String(format: "%.1f", point.primaryPercentage)
            let sevenDay = point.sevenDayPercentage.map { String(format: "%.1f", $0) } ?? ""
            let source = escapeCSVField(point.source)
            return "\(timestamp),\(primary),\(sevenDay),\(source)"
        }

        return ([header] + rows).joined(separator: "\n")
    }

    // MARK: - CSV Export

    /// Show a save panel and export usage data as CSV.
    /// - Parameters:
    ///   - points: Array of usage data points to export.
    ///   - suggestedFilename: Default filename for the save dialog.
    /// - Returns: true if export succeeded, false otherwise.
    static func exportCSV(from points: [UsageDataPoint], suggestedFilename: String = "tokemon-usage.csv") async -> Bool {
        // Critical for LSUIElement apps: activate before showing save panel
        NSApp.activate(ignoringOtherApps: true)

        let panel = NSSavePanel()
        panel.allowedContentTypes = [.commaSeparatedText]
        panel.nameFieldStringValue = suggestedFilename
        panel.canCreateDirectories = true
        panel.title = "Export Usage Data"
        panel.prompt = "Export"

        // Use standalone panel (not beginSheetModal)
        let response = await panel.begin()
        guard response == .OK, let destinationURL = panel.url else {
            return false
        }

        let csvContent = generateCSV(from: points)

        do {
            try csvContent.write(to: destinationURL, atomically: true, encoding: .utf8)
            // Reveal in Finder on success
            NSWorkspace.shared.activateFileViewerSelecting([destinationURL])
            return true
        } catch {
            return false
        }
    }

    // MARK: - Admin API CSV Export

    /// Generate a CSV string from Admin API usage data with 7 columns including cost.
    /// Columns: Date, Total Tokens, Input Tokens, Output Tokens, Cache Read Tokens, Cache Create Tokens, Cost
    /// - Parameters:
    ///   - usage: Admin API usage response.
    ///   - cost: Optional Admin API cost response for cost column.
    ///   - config: Export configuration.
    /// - Returns: CSV-formatted string with header row and data rows.
    static func generateAdminCSV(
        from usage: AdminUsageResponse,
        cost: AdminCostResponse?,
        config: ExportConfig
    ) -> String {
        let header = "Date,Total Tokens,Input Tokens,Output Tokens,Cache Read Tokens,Cache Create Tokens,Cost"

        // Build a lookup for cost by date
        var costByDate: [String: Double] = [:]
        if let cost = cost {
            for bucket in cost.data {
                costByDate[bucket.startingAt] = bucket.totalCost
            }
        }

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"

        let rows = usage.data.map { bucket -> String in
            // Parse ISO8601 date and format as yyyy-MM-dd
            let isoFormatter = ISO8601DateFormatter()
            isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            let date: String
            if let parsedDate = isoFormatter.date(from: bucket.startingAt) {
                date = dateFormatter.string(from: parsedDate)
            } else {
                // Fallback: use the raw startingAt
                date = escapeCSVField(String(bucket.startingAt.prefix(10)))
            }

            let total = String(bucket.totalTokens)
            let input = String(bucket.uncachedInputTokens)
            let output = String(bucket.outputTokens)
            let cacheRead = String(bucket.cacheReadTokens)
            let cacheCreate = String(bucket.cacheCreationTokens)
            let costValue = costByDate[bucket.startingAt].map { String(format: "%.2f", $0) } ?? ""

            return "\(date),\(total),\(input),\(output),\(cacheRead),\(cacheCreate),\(costValue)"
        }

        return ([header] + rows).joined(separator: "\n")
    }

    /// Legacy: Generate a CSV string from Admin API usage data (5 columns, no cost).
    /// - Parameter response: Admin API usage response.
    /// - Returns: CSV-formatted string with header row and data rows.
    static func generateAdminCSV(from response: AdminUsageResponse) -> String {
        let header = "Date,Total Tokens,Input Tokens,Output Tokens,Cache Read Tokens"

        let rows = response.data.map { bucket -> String in
            let date = escapeCSVField(bucket.startingAt)
            let total = String(bucket.totalTokens)
            let input = String(bucket.inputTokens)
            let output = String(bucket.outputTokens)
            let cacheRead = String(bucket.cacheReadTokens)
            return "\(date),\(total),\(input),\(output),\(cacheRead)"
        }

        return ([header] + rows).joined(separator: "\n")
    }

    /// Show a save panel and export Admin API usage data as CSV with cost data.
    /// - Parameters:
    ///   - usage: Admin API usage response to export.
    ///   - cost: Optional Admin API cost response.
    ///   - config: Export configuration with filename.
    /// - Returns: true if export succeeded, false otherwise.
    static func exportAdminCSV(
        from usage: AdminUsageResponse,
        cost: AdminCostResponse?,
        config: ExportConfig
    ) async -> Bool {
        NSApp.activate(ignoringOtherApps: true)

        let panel = NSSavePanel()
        panel.allowedContentTypes = [.commaSeparatedText]
        panel.nameFieldStringValue = config.suggestedFilename
        panel.canCreateDirectories = true
        panel.title = "Export Organization Usage Data"
        panel.prompt = "Export"

        let response = await panel.begin()
        guard response == .OK, let destinationURL = panel.url else {
            return false
        }

        let csvContent = generateAdminCSV(from: usage, cost: cost, config: config)

        do {
            try csvContent.write(to: destinationURL, atomically: true, encoding: .utf8)
            NSWorkspace.shared.activateFileViewerSelecting([destinationURL])
            return true
        } catch {
            return false
        }
    }

    /// Legacy: Show a save panel and export Admin API usage data as CSV.
    /// - Parameters:
    ///   - response: Admin API usage response to export.
    ///   - suggestedFilename: Default filename for the save dialog.
    /// - Returns: true if export succeeded, false otherwise.
    static func exportAdminCSV(from response: AdminUsageResponse, suggestedFilename: String = "tokemon-org-usage.csv") async -> Bool {
        NSApp.activate(ignoringOtherApps: true)

        let panel = NSSavePanel()
        panel.allowedContentTypes = [.commaSeparatedText]
        panel.nameFieldStringValue = suggestedFilename
        panel.canCreateDirectories = true
        panel.title = "Export Organization Usage Data"
        panel.prompt = "Export"

        let response_panel = await panel.begin()
        guard response_panel == .OK, let destinationURL = panel.url else {
            return false
        }

        let csvContent = generateAdminCSV(from: response)

        do {
            try csvContent.write(to: destinationURL, atomically: true, encoding: .utf8)
            NSWorkspace.shared.activateFileViewerSelecting([destinationURL])
            return true
        } catch {
            return false
        }
    }

    // MARK: - Helpers

    /// Escape a field for CSV: wrap in quotes if it contains commas, quotes, or newlines.
    /// Embedded double quotes are escaped by doubling them.
    private static func escapeCSVField(_ field: String) -> String {
        let needsEscaping = field.contains(",") || field.contains("\"") || field.contains("\n") || field.contains("\r")
        guard needsEscaping else { return field }
        let escaped = field.replacingOccurrences(of: "\"", with: "\"\"")
        return "\"\(escaped)\""
    }

    // MARK: - Image Rendering & Clipboard

    /// Render a SwiftUI view to an NSImage.
    /// - Parameters:
    ///   - view: The SwiftUI view to render.
    ///   - scale: The render scale (2.0 for Retina, default).
    /// - Returns: An NSImage of the rendered view, or nil on failure.
    static func renderToImage<V: View>(_ view: V, scale: CGFloat = 2.0) -> NSImage? {
        let renderer = ImageRenderer(content: view)
        renderer.scale = scale

        guard let cgImage = renderer.cgImage else {
            return nil
        }

        // Create NSImage with correct size (cgImage dimensions / scale)
        let size = NSSize(
            width: CGFloat(cgImage.width) / scale,
            height: CGFloat(cgImage.height) / scale
        )
        return NSImage(cgImage: cgImage, size: size)
    }

    /// Copy an NSImage to the system clipboard.
    /// - Parameter image: The image to copy.
    /// - Returns: true if the copy succeeded, false otherwise.
    static func copyImageToClipboard(_ image: NSImage) -> Bool {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents() // CRITICAL: must clear before write
        return pasteboard.writeObjects([image])
    }

    /// Convenience method: render a SwiftUI view and copy to clipboard.
    /// - Parameter view: The SwiftUI view to render and copy.
    /// - Returns: true if render and copy both succeeded, false otherwise.
    static func copyViewToClipboard<V: View>(_ view: V) -> Bool {
        guard let image = renderToImage(view) else {
            return false
        }
        return copyImageToClipboard(image)
    }
}
