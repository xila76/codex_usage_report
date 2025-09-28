package report

import (
	"fmt"
	"time"

	"codex_usage_report/internal/model"
	"codex_usage_report/internal/timeline"
)

// PrintTimeline prints the timeline (clean or full)
func PrintTimeline(entries []model.TimelineEntry, full bool, useEmoji bool) {
	if len(entries) == 0 {
		fmt.Println("⚠️ No timeline data found.")
		return
	}

	iconLine := "📈"
	if !useEmoji {
		iconLine = "[TIMELINE]"
	}

	if full {
		fmt.Printf("%s Global usage timeline (FULL):\n", iconLine)
	} else {
		fmt.Printf("%s Global usage timeline:\n", iconLine)
	}

	for i, entry := range entries {
		fmt.Printf("  %03d | %s → Primary: %d%% | Secondary: %d%%\n",
			i+1, entry.Timestamp, entry.Primary, entry.Secondary)
	}
	fmt.Println()
}

// PrintSummary prints the global summary of tokens and cooldown estimation
func PrintSummary(
	allTimelines [][]model.TimelineEntry,
	globalMax int,
	globalSum int,
	useEmoji bool,
) {
	merged := timeline.MergeTimelines(allTimelines)

	if len(merged) == 0 {
		fmt.Println("⚠️ No data found.")
		return
	}

	last := merged[len(merged)-1]
	iconCheck := "✅"
	iconHourglass := "⏳"
	iconStats := "📊"
	if !useEmoji {
		iconCheck, iconHourglass, iconStats = "[OK]", "[WAIT]", "[STATS]"
	}

	fmt.Printf("%s Last values → Primary: %d%% | Secondary: %d%% (ts=%s)\n",
		iconCheck, last.Primary, last.Secondary, last.Timestamp)

	if cooldown, _ := timeline.EstimateCooldown(merged, time.Now()); cooldown != "" {
		fmt.Printf("%s Estimated recharge in: %s\n", iconHourglass, cooldown)
	}

	fmt.Printf("%s Max total tokens used: %d\n", iconStats, globalMax)
	fmt.Printf("%s Sum of last task tokens: %d\n", iconStats, globalSum)
}

