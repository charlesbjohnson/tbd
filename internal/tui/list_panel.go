package tui

import (
	gloss "github.com/charmbracelet/lipgloss"
)

type ListPanel struct {
	ListItems *ListItems
}

func NewListPanel(items []string) *ListPanel {
	return &ListPanel{
		ListItems: NewListItems(items),
	}
}

func (panel *ListPanel) View(current bool, height, width int) string {
	return gloss.NewStyle().Render(panel.ListItems.View(current, height, width-2))
}
