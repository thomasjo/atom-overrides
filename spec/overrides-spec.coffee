{WorkspaceView} = require "atom"
Overrides = require "../lib/overrides"

allOverrides =
  'source':
    'foo':
      'softTabs': true

    'bar':
      'tabLength': 4

    'python':
      'tabLength': 4
      'softTabs': true

  'text':
    'tabLength': 2
    'softTabs': true

    'foo':
      'softTabs': false
      'tabLength': 8

      'bar':
        'tabLength': 16

describe "Overrides", ->
  [buffer, editor] = []

  beforeEach ->
    atom.workspaceView = new WorkspaceView()
    atom.workspace = atom.workspaceView.model

    waitsForPromise -> atom.packages.activatePackage("overrides")
    waitsForPromise -> atom.packages.activatePackage("language-ruby")
    waitsForPromise -> atom.packages.activatePackage("language-python")

    atom.config.set("editor.tabLength", 2)
    atom.config.set("overrides.scopes", allOverrides)

    editor = atom.workspace.openSync()
    buffer = editor.getBuffer()

  describe "Interoperability with language packages", ->
    it "respects the defaults", ->
      editor.setGrammar(atom.syntax.grammarForScopeName("source.ruby"))
      editor.insertText("if foo\n5\nend")
      editor.autoIndentBufferRow(1)
      expect(buffer.lineForRow(1)).toBe "  5"

    it "can override the defaults", ->
      editor.setGrammar(atom.syntax.grammarForScopeName("source.python"))
      editor.insertText("if foo:\n5\n")
      editor.autoIndentBufferRow(1)
      expect(buffer.lineForRow(1)).toBe "    5"

    it "updates settings when the grammar is changed after the file is opened", ->
      editor.setGrammar(atom.syntax.grammarForScopeName("source.ruby"))
      editor.insertText("if foo:\n5\n")
      editor.setGrammar(atom.syntax.grammarForScopeName("source.python"))
      editor.autoIndentBufferRow(1)
      expect(buffer.lineForRow(1)).toBe "    5"

  describe "getOverridesForScope", ->
    it "returns nothing when given a scope with no overrides", ->
      overrides = Overrides.getOverridesForScope("foo")
      expect(overrides).toEqual {}

    it "returns nothing when given a nested scope with no overrides at any level", ->
      overrides = Overrides.getOverridesForScope("foo.bar")
      expect(overrides).toEqual {}

    it "returns the expected overrides for the given non-cascading scope", ->
      overrides = Overrides.getOverridesForScope("source.python")
      expect(overrides).toEqual {
        "tabLength": 4
        "softTabs": true
      }

    it "returns the cascaded overrides for the given scope", ->
      overrides = Overrides.getOverridesForScope("text.foo.bar")
      expect(overrides).toEqual {
        "tabLength": 16
        "softTabs": false
      }

    it "returns the overrides only to the depth that is requested", ->
      overrides = Overrides.getOverridesForScope("text.foo")
      expect(overrides).toEqual {
        softTabs: false
        tabLength: 8
      }
