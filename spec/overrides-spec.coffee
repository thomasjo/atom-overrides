{WorkspaceView} = require "atom"
Overrides = require "../lib/overrides"

allOverrides =
  "source":
    "foo":
      "softTabs": true
    "bar":
      "tabLength": 4
    "python":
      "tabLength": 4
      "softTabs": true
  "text":
    "tabLength": 2
    "softTabs": true
    "foo":
      "softTabs": false
      "tabLength": 8
      "bar":
        "tabLength": 16

describe "Overrides", ->
  [buffer, editor] = []

  beforeEach ->
    atom.workspaceView = new WorkspaceView
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

    it "maintains the correct settings even when the default configuration is changed", ->
      editor.setGrammar(atom.syntax.grammarForScopeName("source.python"))
      editor.insertText("if foo:\n5\n")
      atom.config.set("editor.tabLength", 8)

      expect(editor.getTabLength()).toBe 4

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
        "softTabs": false
        "tabLength": 8
      }

  describe "watchConfig", ->
    beforeEach ->
      spyOn(Overrides, "applyOverrides")

    it "calls @applyOverrides when the config is updated", ->
      atom.config.set("foo.test", 2)
      expect(Overrides.applyOverrides).toHaveBeenCalled()

    it "does not call @applyOverrides after the package is deactivated", ->
      atom.packages.deactivatePackage("atom-overrides")
      atom.config.set("foo.test", 2)
      expect(Overrides.applyOverrides).not.toHaveBeenCalled()

  describe "setting configuration", ->
    describe "showIndentGuide", ->
      it "sets the attribute", ->
        atom.config.set("overrides.scopes.source.python.showIndentGuide", true)
        spyOn(Overrides.map, "showIndentGuide")

        editor.setGrammar(atom.syntax.grammarForScopeName("source.python"))
        expect(Overrides.map.showIndentGuide.mostRecentCall.args[1]).toBe(true)

      it "does not set the attribute when not configured", ->
        atom.config.set("overrides.scopes.source.python", {})
        spyOn(Overrides.map, "showIndentGuide")

        editor.setGrammar(atom.syntax.grammarForScopeName("source.python"))
        expect(Overrides.map.showIndentGuide).not.toHaveBeenCalled()

    describe "showInvisibles", ->
      it "sets the attribute", ->
        atom.config.set("overrides.scopes.source.python.showInvisibles", true)
        spyOn(Overrides.map, "showInvisibles")

        editor.setGrammar(atom.syntax.grammarForScopeName("source.python"))
        expect(Overrides.map.showInvisibles.mostRecentCall.args[1]).toBe(true)

      it "does not set the attribute when not configured", ->
        atom.config.set("overrides.scopes.source.python", {})
        spyOn(Overrides.map, "showInvisibles")

        editor.setGrammar(atom.syntax.grammarForScopeName("source.python"))
        expect(Overrides.map.showInvisibles).not.toHaveBeenCalled()

    describe "softTabs", ->
      it "sets the attribute", ->
        atom.config.set("overrides.scopes.source.python.softTabs", true)
        spyOn(editor, "setSoftTabs").andCallThrough()

        editor.setGrammar(atom.syntax.grammarForScopeName("source.python"))
        expect(editor.setSoftTabs).toHaveBeenCalledWith(true)
        expect(editor.getSoftTabs()).toBe(true)

      it "does not set the attribute when not configured", ->
        atom.config.set("overrides.scopes.source.python", {})
        spyOn(editor, "setSoftTabs")

        editor.setGrammar(atom.syntax.grammarForScopeName("source.python"))
        expect(editor.setSoftTabs).not.toHaveBeenCalled()

    describe "softWrap", ->
      it "sets the attribute", ->
        atom.config.set("overrides.scopes.source.python.softWrap", true)
        spyOn(editor, "setSoftWrap").andCallThrough()

        editor.setGrammar(atom.syntax.grammarForScopeName("source.python"))
        expect(editor.setSoftWrap).toHaveBeenCalledWith(true)
        expect(editor.getSoftWrap()).toBe(true)

      it "does not set the attribute when not configured", ->
        atom.config.set("overrides.scopes.source.python", {})
        spyOn(editor, "setSoftWrap")

        editor.setGrammar(atom.syntax.grammarForScopeName("source.python"))
        expect(editor.setSoftWrap).not.toHaveBeenCalled()

    describe "tabLength", ->
      it "sets the attribute", ->
        atom.config.set("overrides.scopes.source.python.tabLength", 16)
        spyOn(editor, "setTabLength").andCallThrough()

        editor.setGrammar(atom.syntax.grammarForScopeName("source.python"))
        expect(editor.setTabLength).toHaveBeenCalledWith(16)
        expect(editor.getTabLength()).toBe(16)

      it "does not set the attribute when not configured", ->
        atom.config.set("overrides.scopes.source.python", {})
        spyOn(editor, "setTabLength")

        editor.setGrammar(atom.syntax.grammarForScopeName("source.python"))
        expect(editor.setTabLength).not.toHaveBeenCalled()
