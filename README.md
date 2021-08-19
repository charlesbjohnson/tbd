# TBD

**What:**

An ***experimental*** plugin for tree-oriented editing within Neovim.

![demo](https://user-images.githubusercontent.com/4823640/130010001-68e077ac-ec4b-476a-8f04-c7474c58ab47.gif)

Useful for quickly creating simple text outlines that are structured based on indentation.

Supports:

- Tree-aware navigation
- Inserting a line before/after the current line
- Appending/prepending a line indented below the current line
- Deleting a line, shifting any lines below up
- Deleting a line and all lines below
- Copy and paste
- Undo and redo
- Folding

**Why:**

On any given project I often have a notes directory full of files that match this tree-like, indented format.

It's easy enough to write plain text notes in a text editor, but I'm often wishing that I had a few small enhancements that would make it easier and faster to create notes in this way.

This plugin is an attempt to build something that approximates my desired editing experience using Neovim as a platform.

**Caveats:**

I created this as a Neovim plugin as opposed to a full TUI app for a few reasons:

- I prefer editing in Neovim
- To save time
- I wasn't happy with the TUI "frameworks" that I had trialed

That being said, I found myself reimplementing Vim functionality since I wasn't able to find a satisfactory way to incorporate it into the plugin as-is (specifically undo/redo and folding).

The current functionality is usable, but I likely will not add any additional features in light of the "architecture smell" that is trying to create an editor within an editor.

**Install:**

```lua
use("charlesbjohnson/tbd")
```

**Usage:**

```
:Tbd notes.tbd
```
