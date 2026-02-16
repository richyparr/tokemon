import SwiftUI

/// Detail breakdown below the header.
/// Shows limit remaining, reset time, and usage breakdown for OAuth.
/// Shows token breakdown for JSONL source.
/// Comfortable density with breathing room.
struct UsageDetailView: View {
    let usage: UsageSnapshot
    let showExtraUsage: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if usage.source == .jsonl {
                jsonlRows
            } else {
                oauthRows
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - OAuth Detail Rows

    @ViewBuilder
    private var oauthRows: some View {
        // Note: 5-hour usage and reset timer are shown in UsageHeaderView
        detailRow(
            label: "7-day usage",
            value: usage.sevenDayUtilization?.percentageFormatted ?? "--"
        )

        // Show Sonnet row if available (even if 0%)
        if let sonnetUtil = usage.sevenDaySonnetUtilization {
            detailRow(
                label: "7-day Sonnet",
                value: sonnetUtil.percentageFormatted
            )
        }

        // Only show Opus row if non-nil and non-zero
        if let opusUtil = usage.sevenDayOpusUtilization, opusUtil > 0 {
            detailRow(
                label: "7-day Opus",
                value: opusUtil.percentageFormatted
            )
        }

        // Extra usage section (if enabled and user wants to see it)
        if showExtraUsage && usage.extraUsageEnabled {
            Divider()
                .padding(.vertical, 4)

            Text("Extra Usage")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)

            detailRow(
                label: "Spent this month",
                value: usage.formattedExtraUsageSpent
            )

            detailRow(
                label: "Monthly limit",
                value: usage.formattedMonthlyLimit
            )

            if let utilization = usage.extraUsageUtilization {
                detailRow(
                    label: "Limit used",
                    value: utilization.percentageFormatted
                )
            }
        }
    }

    // MARK: - JSONL Detail Rows

    @ViewBuilder
    private var jsonlRows: some View {
        detailRow(
            label: "Input tokens",
            value: (usage.inputTokens ?? 0).formattedTokenCount
        )
        detailRow(
            label: "Output tokens",
            value: (usage.outputTokens ?? 0).formattedTokenCount
        )

        let cacheTotal = (usage.cacheCreationTokens ?? 0) + (usage.cacheReadTokens ?? 0)
        if cacheTotal > 0 {
            detailRow(
                label: "Cache tokens",
                value: cacheTotal.formattedTokenCount
            )
        }

        detailRow(
            label: "Model",
            value: usage.model ?? "--"
        )
    }

    // MARK: - Helper

    private func detailRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.body)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.body)
                .fontWeight(.medium)
        }
        .padding(.vertical, 1)
    }
}
