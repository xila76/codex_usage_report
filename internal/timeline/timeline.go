package timeline

import (
	"sort"
	"time"

	"codex_usage_report/internal/model"
	"codex_usage_report/pkg/utils"
)

// MergeTimelines merges multiple timelines and sorts them by timestamp
func MergeTimelines(all [][]model.TimelineEntry) []model.TimelineEntry {
	var merged []model.TimelineEntry
	for _, t := range all {
		merged = append(merged, t...)
	}
	sort.Slice(merged, func(i, j int) bool {
		return merged[i].Timestamp < merged[j].Timestamp
	})
	return merged
}

// parseTS parses an RFC3339 timestamp; if it fails, returns zero time
func parseTS(ts string) time.Time {
	t, _ := time.Parse(time.RFC3339, ts)
	return t
}

// findLatestZeroBeforeEnd finds the last index where the value == 0.
// If not found, returns -1.
func findLatestZeroBeforeEnd(vals []int) int {
	for i := len(vals) - 1; i >= 0; i-- {
		if vals[i] == 0 {
			return i
		}
	}
	return -1
}

// EstimateCooldown estimates cooldown based on the rules:
// (i) If Secondary == 100% → 7 days from the start of the cycle
//     (last Secondary == 0 before reaching 100%)
// (ii) If Secondary < 100% and Primary == 100% → 5h from the start of the cycle
//     (last Primary == 0 before reaching 100%)
// Fallback: if no "0%" is found in history, use the first timestamp of the log.
func EstimateCooldown(timeline []model.TimelineEntry, now time.Time) (string, error) {
	if len(timeline) == 0 {
		return "", nil
	}

	last := timeline[len(timeline)-1]
	var cycleStart time.Time
	var duration time.Duration

	switch {
	case last.Secondary == 100:
		// weekly cycle from the last Secondary==0
		secVals := make([]int, len(timeline))
		for i, e := range timeline {
			secVals[i] = e.Secondary
		}

		idx := findLatestZeroBeforeEnd(secVals)
		if idx >= 0 {
			// cycle starts at the reset moment (0%)
			cycleStart = parseTS(timeline[idx].Timestamp)
		} else {
			// fallback: use first timestamp in the log
			cycleStart = parseTS(timeline[0].Timestamp)
		}
		duration = 7 * 24 * time.Hour

	case last.Primary == 100 && last.Secondary < 100:
		// 5h cycle from the last Primary==0
		priVals := make([]int, len(timeline))
		for i, e := range timeline {
			priVals[i] = e.Primary
		}

		idx := findLatestZeroBeforeEnd(priVals)
		if idx >= 0 {
			cycleStart = parseTS(timeline[idx].Timestamp)
		} else {
			cycleStart = parseTS(timeline[0].Timestamp)
		}
		duration = 5 * time.Hour

	default:
		// nothing to estimate at this moment
		return "", nil
	}

	// calculate end time and format result
	if cycleStart.IsZero() {
		cycleStart = parseTS(timeline[0].Timestamp)
	}
	endTime := cycleStart.Add(duration)
	if endTime.Before(now) {
		return "already completed", nil
	}
	return utils.FormatDuration(endTime.Sub(now)), nil
}

