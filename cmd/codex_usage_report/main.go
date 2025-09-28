package main

import (
	"flag"
	"fmt"
	"os"
	"path/filepath"
	"strings"

	"codex_usage_report/internal/model"
	"codex_usage_report/internal/parser"
	"codex_usage_report/internal/report"
	"codex_usage_report/internal/timeline"
)

var version = "0.1.0" // override with: go build -ldflags "-X main.version=0.1.1"

// global for language (en default)
var lang = "en"

func main() {
	showTimeline := flag.Bool("timeline", false, "Show chronological evolution (deduplicated)")
	showFullTimeline := flag.Bool("full-timeline", false, "Show raw timeline (with repetitions)")
	showDebug := flag.Bool("debug", false, "Verbose parsing debug")
	noEmoji := flag.Bool("no-emoji", false, "Disable emoji/icons in output")
	customSessions := flag.String("sessions-dir", "", "Override sessions directory (default: ~/.codex/sessions)")
	showVersion := flag.Bool("version", false, "Print version and exit")
	langFlag := flag.String("lang", "", "Force language: en or pt (default: auto-detect)")

	// override default usage
	flag.Usage = func() {
		if lang == "pt" {
			fmt.Fprintf(os.Stderr, "Uso: %s [flags]\n\n", os.Args[0])
			fmt.Fprintln(os.Stderr, "Flags disponíveis:")
			fmt.Fprintln(os.Stderr, "  --timeline        Mostrar evolução cronológica (sem repetições)")
			fmt.Fprintln(os.Stderr, "  --full-timeline   Mostrar timeline completa (com repetições)")
			fmt.Fprintln(os.Stderr, "  --no-emoji        Desativar ícones/emoji na saída")
			fmt.Fprintln(os.Stderr, "  --debug           Mostrar logs detalhados de parsing")
			fmt.Fprintln(os.Stderr, "  --sessions-dir    Definir outro diretório de sessões (default: ~/.codex/sessions)")
			fmt.Fprintln(os.Stderr, "  --lang en|pt      Forçar idioma (padrão: auto)")
			fmt.Fprintln(os.Stderr, "  --version         Mostrar versão e sair")
		} else {
			fmt.Fprintf(os.Stderr, "Usage: %s [flags]\n\n", os.Args[0])
			fmt.Fprintln(os.Stderr, "Available flags:")
			fmt.Fprintln(os.Stderr, "  --timeline        Show chronological evolution (deduplicated)")
			fmt.Fprintln(os.Stderr, "  --full-timeline   Show raw timeline (with repetitions)")
			fmt.Fprintln(os.Stderr, "  --no-emoji        Disable emoji/icons in output")
			fmt.Fprintln(os.Stderr, "  --debug           Verbose parsing debug")
			fmt.Fprintln(os.Stderr, "  --sessions-dir    Set another sessions dir (default: ~/.codex/sessions)")
			fmt.Fprintln(os.Stderr, "  --lang en|pt      Force language (default: auto)")
			fmt.Fprintln(os.Stderr, "  --version         Print version and exit")
		}
	}

	flag.Parse()

	// auto-detect language if not forced
	if *langFlag != "" {
		lang = *langFlag
	} else {
		if envLang := os.Getenv("LANG"); strings.HasPrefix(envLang, "pt") {
			lang = "pt"
		}
	}

	if *showVersion {
		fmt.Println("codex_usage_report", version)
		return
	}

	homeDir, err := os.UserHomeDir()
	if err != nil {
		if lang == "pt" {
			fmt.Printf("❌ Erro ao obter diretório home: %v\n", err)
		} else {
			fmt.Printf("❌ Failed to resolve home dir: %v\n", err)
		}
		return
	}

	baseDir := *customSessions
	if baseDir == "" {
		baseDir = filepath.Join(homeDir, ".codex", "sessions")
	}

	iconFolder := "📂"
	if *noEmoji {
		if lang == "pt" {
			iconFolder = "[DIR]"
		} else {
			iconFolder = "[DIR]"
		}
	}
	if lang == "pt" {
		fmt.Printf("%s Lendo sessões em: %s\n", iconFolder, baseDir)
	} else {
		fmt.Printf("%s Reading sessions from: %s\n", iconFolder, baseDir)
	}

	files, err := parser.FindSessionFiles(baseDir)
	if err != nil {
		if lang == "pt" {
			fmt.Printf("❌ Erro ao buscar arquivos: %v\n", err)
		} else {
			fmt.Printf("❌ Failed to list session files: %v\n", err)
		}
		return
	}
	if len(files) == 0 {
		if lang == "pt" {
			fmt.Println("⚠️ Nenhum arquivo de sessão encontrado.")
		} else {
			fmt.Println("⚠️ No session file found.")
		}
		return
	}

	var (
		allTimelines   [][]model.TimelineEntry
		globalMax      int
		globalSum      int
		timelineToShow []model.TimelineEntry
	)

	for _, file := range files {
		if lang == "pt" {
			fmt.Printf("📑 Analisando: %s\n", file)
		} else {
			fmt.Printf("📑 Analyzing: %s\n", file)
		}
		tlFull, tlClean, maxTotal, sumLast, err := parser.ParseFile(file, *showDebug)
		if err != nil {
			if lang == "pt" {
				fmt.Printf("❌ Erro ao processar %s: %v\n", file, err)
			} else {
				fmt.Printf("❌ Error reading %s: %v\n", file, err)
			}
			continue
		}

		allTimelines = append(allTimelines, tlClean)

		if *showFullTimeline {
			timelineToShow = append(timelineToShow, tlFull...)
		} else if *showTimeline {
			timelineToShow = append(timelineToShow, tlClean...)
		}

		if maxTotal > globalMax {
			globalMax = maxTotal
		}
		globalSum += sumLast
	}

	if *showTimeline || *showFullTimeline {
		fmt.Println()
		report.PrintTimeline(
			timeline.MergeTimelines([][]model.TimelineEntry{timelineToShow}),
			*showFullTimeline,
			!*noEmoji,
		)
		fmt.Println()
	}

	report.PrintSummary(allTimelines, globalMax, globalSum, !*noEmoji)
}

