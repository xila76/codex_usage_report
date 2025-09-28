package utils

import (
	"fmt"
	"time"
)

// FormatDuration converts a duration into "X days, Y hours and Z minutes"
func FormatDuration(d time.Duration) string {
	if d < 0 {
		d = 0
	}
	days := int(d.Hours()) / 24
	hours := int(d.Hours()) % 24
	minutes := int(d.Minutes()) % 60

	if days > 0 {
		return fmt.Sprintf("%d days, %d hours and %d minutes", days, hours, minutes)
	}
	if hours > 0 {
		return fmt.Sprintf("%d hours and %d minutes", hours, minutes)
	}
	return fmt.Sprintf("%d minutes", minutes)
}


