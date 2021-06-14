package tui

import (
	tea "github.com/charmbracelet/bubbletea"
)

type App struct {
	height int
	width  int

	ListPanels *ListPanels
}

func NewApp() *App {
	return &App{
		ListPanels: NewListPanels(
			[]string{"foo", "bar", "baz"},
			[]string{"qux", "qux", "quuz"},
			[]string{"corge", "grault", "waldo"},
		),
	}
}

func (app *App) Init() tea.Cmd {
	return nil
}

func (app *App) Update(msg tea.Msg) (tea.Model, tea.Cmd) {
	switch msg := msg.(type) {
	case tea.WindowSizeMsg:
		app.height = msg.Height
		app.width = msg.Width
	case tea.KeyMsg:
		switch msg.String() {
		case "esc":
			return app, tea.Quit
		case "h":
			return app, func() tea.Msg { return PreviousListPanel }
		case "j":
			return app, func() tea.Msg { return NextListItem }
		case "k":
			return app, func() tea.Msg { return PreviousListItem }
		case "l":
			return app, func() tea.Msg { return NextListPanel }
		case "o":
			return app, func() tea.Msg { return AppendListItem }
		case "O":
			return app, func() tea.Msg { return PrependListItem }
		}
	}

	return app, app.ListPanels.Update(msg)
}

func (app *App) View() string {
	return app.ListPanels.View(app.height, app.width)
}
