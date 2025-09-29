package parser

import (
	"os"
	"path/filepath"
	"testing"
)

func TestParseFileWithFractionalPrimaryPercent(t *testing.T) {
	dir := t.TempDir()
	filePath := filepath.Join(dir, "rollout-test.jsonl")

	content := `{"timestamp":"2024-01-01T00:00:00Z","payload":{"info":{"total_token_usage":{"total_tokens":10},"last_token_usage":{"total_tokens":5}},"rate_limits":{"primary_used_percent":0.42,"secondary_used_percent":0.0}}}`
	if err := os.WriteFile(filePath, []byte(content+"\n"), 0644); err != nil {
		t.Fatalf("failed to write test file: %v", err)
	}

	timelineFull, _, _, _, err := ParseFile(filePath, false)
	if err != nil {
		t.Fatalf("ParseFile returned error: %v", err)
	}

	if len(timelineFull) == 0 {
		t.Fatalf("expected at least one timeline entry, got 0")
	}
}
