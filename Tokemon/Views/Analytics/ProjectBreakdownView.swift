import SwiftUI

/// Displays per-project token usage breakdown from JSONL session files.
/// Cross-account: aggregates all JSONL data on the machine.
/// Pro-gated: requires .projectBreakdown access.
struct ProjectBreakdownView: View {
    @State private var projects: [ProjectUsage] = []
    @State private var isLoading = false
    @State private var selectedTimeRange: ProjectTimeRange = .month

    enum ProjectTimeRange: String, CaseIterable {
        case week = "7d"
        case month = "30d"
        case quarter = "90d"

        var interval: TimeInterval {
            switch self {
            case .week: return 7 * 24 * 3600
            case .month: return 30 * 24 * 3600
            case .quarter: return 90 * 24 * 3600
            }
        }
    }

    private var maxTokens: Int {
        projects.first?.totalTokens ?? 1
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Project Breakdown")
                    .font(.headline)
                Text("This Machine")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(
                        RoundedRectangle(cornerRadius: 4)
                            .fill(.quaternary)
                    )
                Spacer()
                Picker("", selection: $selectedTimeRange) {
                    ForEach(ProjectTimeRange.allCases, id: \.self) { range in
                        Text(range.rawValue).tag(range)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 150)
                .onChange(of: selectedTimeRange) { _, _ in
                    loadProjects()
                }
            }

            if isLoading {
                // Loading state
                VStack(spacing: 8) {
                    ProgressView()
                        .controlSize(.small)
                    Text("Analyzing session files...")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
            } else if projects.isEmpty {
                // Empty state
                VStack(spacing: 4) {
                    Text("No project data found")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
            } else {
                // Project list
                ForEach(projects) { project in
                    ProjectRow(project: project, maxTokens: maxTokens)
                }
            }
        }
        .onAppear {
            loadProjects()
        }
    }

    private func loadProjects() {
        isLoading = true
        Task.detached { [selectedTimeRange] in
            let since = Date().addingTimeInterval(-selectedTimeRange.interval)
            let result = AnalyticsEngine.projectBreakdown(since: since)
            await MainActor.run {
                self.projects = result
                self.isLoading = false
            }
        }
    }
}

/// A single row in the project breakdown list.
private struct ProjectRow: View {
    let project: ProjectUsage
    let maxTokens: Int

    private var proportion: Double {
        guard maxTokens > 0 else { return 0 }
        return Double(project.totalTokens) / Double(maxTokens)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(project.projectName)
                    .font(.callout)
                    .fontWeight(.medium)
                Spacer()
                Text(AnalyticsEngine.formatTokenCount(project.totalTokens))
                    .font(.callout)
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
                Text("\(project.sessionCount) sessions")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }

            // Relative proportion bar
            GeometryReader { geometry in
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.accentColor.opacity(0.3))
                    .frame(width: geometry.size.width * proportion, height: 4)
            }
            .frame(height: 4)
        }
        .padding(.vertical, 2)
    }
}
