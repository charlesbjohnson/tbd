package tui

import (
	gloss "github.com/charmbracelet/lipgloss"
)

type ListItem struct {
	Content string
}

func NewListItem(item string) *ListItem {
	return &ListItem{
		Content: item,
	}
}

func (item *ListItem) View(current bool, _, width int) string {
	style := gloss.NewStyle().Width(width)

	if current {
		style = style.Background(gloss.Color("255")).Foreground(gloss.Color("0"))
	}

	return style.Render(item.Content)
}
