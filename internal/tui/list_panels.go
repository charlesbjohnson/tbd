package tui

import (
	"github.com/charlesbjohnson/tbd/internal/util"

	tea "github.com/charmbracelet/bubbletea"
	gloss "github.com/charmbracelet/lipgloss"
)

type ListPanelsMsg int

const (
	NextListPanel ListPanelsMsg = iota
	PreviousListPanel
)

type ListPanels struct {
	CurrentListPanel int
	ListPanels       []*ListPanel
}

func NewListPanels(lists ...[]string) *ListPanels {
	panels := &ListPanels{}

	for _, list := range lists {
		panels.ListPanels = append(panels.ListPanels, NewListPanel(list))
	}

	return panels
}

func (panels *ListPanels) Update(msg tea.Msg) tea.Cmd {
	var cmds []tea.Cmd

	switch msg := msg.(type) {
	case ListPanelsMsg:
		switch msg {
		case NextListPanel:
			panels.CurrentListPanel = util.Min(panels.CurrentListPanel+1, len(panels.ListPanels)-1)
		case PreviousListPanel:
			panels.CurrentListPanel = util.Max(panels.CurrentListPanel-1, 0)
		}
	}

	for i, panel := range panels.ListPanels {
		if i == panels.CurrentListPanel {
			cmds = append(cmds, panel.ListItems.Update(msg))
		}
	}

	return tea.Batch(cmds...)
}

func (panels *ListPanels) View(height, width int) string {
	var rendered []string

	for i, panel := range panels.ListPanels {
		rendered = append(rendered, panel.View(i == panels.CurrentListPanel, height, width/len(panels.ListPanels)))
	}

	return gloss.JoinHorizontal(gloss.Top, rendered...)
}
