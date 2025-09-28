# 📊 codex_usage_report

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
![Go Version](https://img.shields.io/badge/Go-1.21%2B-blue)

Go tool to analyze **OpenAI Codex** session files (`.jsonl`) and generate reports on token usage, consumption evolution, and cooldown (rate limit recharge) estimates.

---

## 🚀 Features

- Reads multiple session files from `~/.codex/sessions/`  
- Robust **JSON parser** with regex fallback  
- Global aggregated token report  
- Clean timeline (`--timeline`)  
- Full timeline without filtering (`--full-timeline`)  
- Cooldown estimation (rate limit recharge)  
- Supports Linux, macOS, and Windows  
- Option to disable emojis (`--no-emoji`)  

---

## 🛠️ Build

Requirements: **Go 1.21+**

Clone the project and run:

    make build

The binaries will be placed in `dist/`.

To generate builds for **all supported platforms**:

    make release

---

## ▶️ Usage

    ./dist/codex_usage_report [flags]

### Available flags:
- `--timeline` → shows chronological evolution (without repetitions)  
- `--full-timeline` → shows the raw timeline (with repetitions)  
- `--no-emoji` → disables emojis in the output  
- `--debug` → prints detailed parsing logs  

Example:

    ./dist/codex_usage_report --timeline

---

## 💻 Installation

### Linux/macOS

1. Build the binary:
   
       make build

2. Copy it into your PATH:
   
       sudo cp dist/codex_usage_report /usr/local/bin/

3. Run from anywhere:
   
       codex_usage_report --timeline

### Windows

1. Build:
   
       make build

   or grab the binary from `dist/codex_usage_report_windows_amd64.exe`.

2. Copy it to a folder in your **PATH** (e.g. `C:\Windows\System32` or set up `C:\bin` in PATH).  

3. Run from anywhere in PowerShell or Command Prompt:
   
       codex_usage_report.exe --timeline

---

## ⚡ Quick install via script

### Linux/macOS

    ./install.sh

The script copies the binary to `/usr/local/bin`.

### Windows

    install.bat

The script copies the `.exe` to your Windows PATH.

---

## 📂 Project structure

    codex_usage_report/
    ├── cmd/
    │   └── codex_usage_report/   # entrypoint (main.go)
    ├── internal/                 # internal project code
    │   ├── parser/               # JSONL parser
    │   ├── timeline/             # timeline + cooldown logic
    │   └── report/               # global summary + printing
    ├── pkg/
    │   └── utils/                # helper functions (timefmt.go)
    ├── dist/                     # build outputs
    ├── Makefile                  # build/release
    ├── go.mod
    └── README.md

