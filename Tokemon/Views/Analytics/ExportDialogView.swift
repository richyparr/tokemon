import SwiftUI

/// Two-step export dialog for selecting data source and date range.
/// Step 1: Select source (local or organization) — skipped for local-only users
/// Step 2: Select date range from presets or custom
/// Step 3: Exporting state with progress indicator
struct ExportDialogView: View {
    let format: ExportFormat
    let onExport: (ExportConfig) async -> Bool
    let onCancel: () -> Void

    enum Step {
        case selectSource
        case selectDateRange
        case exporting
    }

    @State private var step: Step = .selectSource
    @State private var selectedSource: ExportSource = .local
    @State private var selectedPreset: DatePreset = .thirtyDays
    @State private var customStartDate: Date = Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? Date()
    @State private var customEndDate: Date = Date()
    @State private var exportStatus: String = "Preparing export..."

    private var hasAdminKey: Bool {
        AdminAPIClient.shared.hasAdminKey()
    }

    var body: some View {
        VStack(spacing: 0) {
            if step == .exporting {
                exportingStep
            } else if !hasAdminKey || step == .selectDateRange {
                dateRangeStep
            } else {
                sourceSelectionStep
            }
        }
        .frame(width: 400)
        .onAppear {
            // Skip source selection for local-only users
            if !hasAdminKey {
                selectedSource = .local
                step = .selectDateRange
            }
        }
    }

    // MARK: - Step 1: Source Selection

    @ViewBuilder
    private var sourceSelectionStep: some View {
        VStack(spacing: 20) {
            // Header
            Text("Export \(formatTitle)")
                .font(.headline)

            Text("Choose data source")
                .font(.callout)
                .foregroundStyle(.secondary)

            // Source options
            VStack(spacing: 8) {
                ForEach(ExportSource.allCases, id: \.self) { source in
                    if source == .local || hasAdminKey {
                        sourceRow(source)
                    }
                }
            }

            // Buttons
            HStack {
                Button("Cancel") {
                    onCancel()
                }
                .buttonStyle(.bordered)

                Spacer()

                Button("Next") {
                    step = .selectDateRange
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(20)
    }

    @ViewBuilder
    private func sourceRow(_ source: ExportSource) -> some View {
        Button {
            selectedSource = source
        } label: {
            HStack {
                Image(systemName: source.icon)
                    .frame(width: 24)
                    .foregroundStyle(selectedSource == source ? .blue : .secondary)

                VStack(alignment: .leading, spacing: 2) {
                    Text(source.rawValue)
                        .fontWeight(.medium)
                        .foregroundStyle(.primary)
                    Text(source.description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if selectedSource == source {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.blue)
                }
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 12)
            .background(selectedSource == source ? Color.blue.opacity(0.1) : Color.gray.opacity(0.1))
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Step 2: Date Range Selection

    @ViewBuilder
    private var dateRangeStep: some View {
        VStack(spacing: 20) {
            // Header with back button
            HStack {
                if hasAdminKey {
                    Button {
                        step = .selectSource
                    } label: {
                        Image(systemName: "chevron.left")
                    }
                    .buttonStyle(.plain)
                }

                Spacer()

                Text("Select Date Range")
                    .font(.headline)

                Spacer()

                // Balance the back button
                if hasAdminKey {
                    Color.clear.frame(width: 24)
                }
            }

            // Preset selection grid
            presetGrid

            // Custom date pickers (shown only when Custom is selected)
            if selectedPreset == .custom {
                customDatePickers
            } else {
                // Show computed date range for non-custom presets
                dateRangePreview
            }

            // Large export warning
            if isLargeExport {
                largeExportWarning
            }

            // Buttons
            HStack {
                Button("Cancel") {
                    onCancel()
                }
                .buttonStyle(.bordered)

                Spacer()

                Button("Export") {
                    startExport()
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(20)
    }

    // MARK: - Step 3: Exporting

    @ViewBuilder
    private var exportingStep: some View {
        VStack(spacing: 20) {
            Text("Exporting \(formatTitle)")
                .font(.headline)

            VStack(spacing: 16) {
                ProgressView()
                    .scaleEffect(1.5)

                Text(exportStatus)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .frame(height: 100)

            Text("This may take a moment for large date ranges...")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(20)
    }

    private func startExport() {
        let config = ExportConfig(
            source: selectedSource,
            datePreset: selectedPreset,
            format: format,
            customStartDate: selectedPreset == .custom ? customStartDate : nil,
            customEndDate: selectedPreset == .custom ? customEndDate : nil
        )

        // Update status based on source
        if selectedSource == .organization {
            exportStatus = "Fetching data from Admin API..."
        } else {
            exportStatus = "Preparing local data..."
        }

        step = .exporting

        Task {
            // Small delay to let the UI update
            try? await Task.sleep(for: .milliseconds(100))

            if selectedSource == .organization {
                exportStatus = "Fetching usage data (\(numberOfDays) days)..."
            }

            let success = await onExport(config)

            if !success {
                // If export failed/cancelled, go back to date selection
                step = .selectDateRange
            }
            // If success, the dialog will be dismissed by the parent
        }
    }

    @ViewBuilder
    private var presetGrid: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible()),
        ], spacing: 8) {
            ForEach(DatePreset.allCases, id: \.self) { preset in
                presetButton(preset)
            }
        }
    }

    @ViewBuilder
    private func presetButton(_ preset: DatePreset) -> some View {
        Button {
            selectedPreset = preset
        } label: {
            Text(preset.rawValue)
                .font(.callout)
                .fontWeight(selectedPreset == preset ? .semibold : .regular)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(selectedPreset == preset ? Color.blue : Color.gray.opacity(0.15))
                .foregroundStyle(selectedPreset == preset ? .white : .primary)
                .cornerRadius(6)
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var customDatePickers: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Start Date")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    DatePicker(
                        "",
                        selection: $customStartDate,
                        in: ...customEndDate,
                        displayedComponents: .date
                    )
                    .labelsHidden()
                    .datePickerStyle(.compact)
                }

                Spacer()

                VStack(alignment: .leading, spacing: 4) {
                    Text("End Date")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    DatePicker(
                        "",
                        selection: $customEndDate,
                        in: customStartDate...Date(),
                        displayedComponents: .date
                    )
                    .labelsHidden()
                    .datePickerStyle(.compact)
                }
            }
        }
        .padding(12)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
    }

    @ViewBuilder
    private var dateRangePreview: some View {
        Text(formattedDateRange)
            .font(.callout)
            .foregroundStyle(.secondary)
    }

    private var formattedDateRange: String {
        let range = selectedPreset.dateRange()
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return "\(formatter.string(from: range.start)) – \(formatter.string(from: range.end))"
    }

    @ViewBuilder
    private var largeExportWarning: some View {
        HStack(spacing: 8) {
            Image(systemName: "info.circle")
                .foregroundStyle(.blue)
            Text("This export covers \(numberOfDays) days of data and may take a moment to fetch.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(10)
        .background(Color.blue.opacity(0.1))
        .cornerRadius(8)
    }

    // MARK: - Computed Properties

    private var formatTitle: String {
        switch format {
        case .pdf: return "PDF Report"
        case .csv: return "CSV Data"
        case .card: return "Usage Card"
        }
    }

    private var numberOfDays: Int {
        let range: (start: Date, end: Date)
        if selectedPreset == .custom {
            range = (customStartDate, customEndDate)
        } else {
            range = selectedPreset.dateRange()
        }

        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: range.start, to: range.end)
        return max(1, components.day ?? 1)
    }

    private var isLargeExport: Bool {
        selectedSource == .organization && numberOfDays > 90
    }
}
