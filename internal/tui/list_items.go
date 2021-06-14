package tui

import (
	"fmt"
	"strings"

	"github.com/charlesbjohnson/tbd/internal/util"
	tea "github.com/charmbracelet/bubbletea"
)

type ListItemsMsg int

const (
	NextListItem ListItemsMsg = iota
	PreviousListItem

	AppendListItem
	PrependListItem
)

type ListItems struct {
	CurrentItem int
	Items       []*ListItem
}

func NewListItems(items []string) *ListItems {
	list := &ListItems{}

	for _, item := range items {
		list.Items = append(list.Items, NewListItem(item))
	}

	return list
}

func (list *ListItems) Update(msg tea.Msg) tea.Cmd {
	switch msg := msg.(type) {
	case ListItemsMsg:
		switch msg {
		case NextListItem:
			list.CurrentItem = util.Min(list.CurrentItem+1, len(list.Items)-1)
		case PreviousListItem:
			list.CurrentItem = util.Max(list.CurrentItem-1, 0)

		case AppendListItem:
			list.CurrentItem++
			list.Items = append(list.Items[:list.CurrentItem], append([]*ListItem{NewListItem("appended")}, list.Items[list.CurrentItem:]...)...)
		case PrependListItem:
			list.Items = append(list.Items[:list.CurrentItem], append([]*ListItem{NewListItem("prepended")}, list.Items[list.CurrentItem:]...)...)
			list.CurrentItem++
		}
	}

	return nil
}

func (list *ListItems) View(current bool, height, width int) string {
	builder := strings.Builder{}

	for i, item := range list.Items {
		builder.WriteString(fmt.Sprintln(item.View(current && i == list.CurrentItem, height, width)))
	}

	return builder.String()
}
