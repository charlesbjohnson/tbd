package tui

import (
	"log"

	tea "github.com/charmbracelet/bubbletea"
)

func Start() {
	program := tea.NewProgram(NewApp(), tea.WithAltScreen())
	if err := program.Start(); err != nil {
		log.Fatal("fail")
	}
}
