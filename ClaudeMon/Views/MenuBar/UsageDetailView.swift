import SwiftUI

/// Detail breakdown below the header.
/// Shows limit remaining, reset time, and usage breakdown for OAuth.
/// Shows token breakdown for JSONL source.
/// Comfortable density with breathing room.
struct UsageDetailView: View {
    let usage: UsageSnapshot

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
        detailRow(
            label: "Resets in",
            value: usage.resetsAt?.formattedResetTime() ?? "--"
        )
        detailRow(
            label: "5-hour usage",
            value: usage.fiveHourUtilization?.percentageFormatted ?? "--"
        )
        detailRow(
            label: "7-day usage",
            value: usage.sevenDayUtilization?.percentageFormatted ?? "--"
        )

        // Only show Opus row if non-nil and non-zero
        if let opusUtil = usage.sevenDayOpusUtilization, opusUtil > 0 {
            detailRow(
                label: "7-day Opus",
                value: opusUtil.percentageFormatted
            )
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
