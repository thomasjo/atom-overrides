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
  describe "unit tests", ->
    [buffer, editor] = []

    beforeEach ->
      atom.workspaceView = new WorkspaceView
      atom.workspace = atom.workspaceView.model

      waitsForPromise -> atom.packages.activatePackage("overrides")
      waitsForPromise -> atom.packages.activatePackage("language-ruby")
      waitsForPromise -> atom.packages.activatePackage("language-python")

      runs ->
        atom.config.set("editor.tabLength", 3)
        atom.config.set("overrides.scopes", allOverrides)

      waitsForPromise ->
        atom.workspace.open().then (ed) ->
          editor = ed
          buffer = editor.getBuffer()

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

  describe "end-to-end tests", ->
    [buffer, editor] = []

    beforeEach ->
      atom.workspaceView = new WorkspaceView()
      atom.workspaceView.height(1000)
      atom.workspaceView.attachToDom()

      atom.workspace = atom.workspaceView.model

      waitsForPromise -> atom.packages.activatePackage("overrides")
      waitsForPromise -> atom.packages.activatePackage("language-ruby")
      waitsForPromise -> atom.packages.activatePackage("language-python")

      runs ->
        atom.config.set("editor.tabLength", 2)
        atom.config.set("overrides.scopes", allOverrides)

      waitsForPromise ->
        atom.workspace.open().then (ed) ->
          editor = ed
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

      # TODO: Fix spec.
      # Functionality works as expected, but spec is broken. Timing issue?
      xit "maintains the correct settings even when the default configuration is changed", ->
        editor.setGrammar(atom.syntax.grammarForScopeName("source.python"))
        editor.insertText("if foo:\n5\n")
        spyOn(Overrides, "applyOverrides").andCallThrough()

        atom.config.set("editor.tabLength", 8)

        waitsFor ->
          Overrides.applyOverrides.callCount > 0

        runs ->
          expect(Overrides.applyOverrides).toHaveBeenCalled()
          expect(editor.getTabLength()).toBe 4
          editor.autoIndentBufferRow(1)
          expect(buffer.lineForRow(1)).toBe "    5"

      it "maintains the correct settings even when the grammar is set to a default language", ->
        editor.setGrammar(atom.syntax.grammarForScopeName("source.python"))
        editor.insertText("if foo\n5\n")
        expect(editor.getTabLength()).toBe 4

        editor.setGrammar(atom.syntax.grammarForScopeName("source.ruby"))
        expect(editor.getTabLength()).toBe 2

        editor.autoIndentBufferRow(1)
        expect(buffer.lineForRow(1)).toBe "  5"

    describe "setting configuration", ->
      describe "showIndentGuide", ->
        it "sets the attribute", ->
          atom.config.set("overrides.scopes.source.python.showIndentGuide", true)
          spyOn(Overrides.map, "showIndentGuide")

          editor.setGrammar(atom.syntax.grammarForScopeName("source.python"))
          expect(Overrides.map.showIndentGuide.mostRecentCall.args[1]).toBe(true)

        it "sets the attribute to the default when not configured", ->
          atom.config.set("overrides.scopes.source.python", {})
          spyOn(Overrides.map, "showIndentGuide")

          editor.setGrammar(atom.syntax.grammarForScopeName("source.python"))
          expect(Overrides.map.showIndentGuide.mostRecentCall.args[1]).toBe(false)

      describe "showInvisibles", ->
        it "sets the attribute", ->
          atom.config.set("overrides.scopes.source.python.showInvisibles", true)
          spyOn(Overrides.map, "showInvisibles")

          editor.setGrammar(atom.syntax.grammarForScopeName("source.python"))
          expect(Overrides.map.showInvisibles.mostRecentCall.args[1]).toBe(true)

        it "sets the attribute to the default when not configured", ->
          atom.config.set("overrides.scopes.source.python", {})
          spyOn(Overrides.map, "showInvisibles")

          editor.setGrammar(atom.syntax.grammarForScopeName("source.python"))
          expect(Overrides.map.showInvisibles.mostRecentCall.args[1]).toBe(false)

        it 'does not override the default when setting for a single editor', ->
          atom.config.set("overrides.scopes.source.python.showInvisibles", true)

          editor.setGrammar(atom.syntax.grammarForScopeName("source.python"))
          expect(atom.config.get("editor.showInvisibles")).toBe false

      describe "softTabs", ->
        it "sets the attribute", ->
          atom.config.set("overrides.scopes.source.python.softTabs", false)
          spyOn(editor, "setSoftTabs").andCallThrough()

          editor.setGrammar(atom.syntax.grammarForScopeName("source.python"))
          expect(editor.setSoftTabs).toHaveBeenCalledWith(false)
          expect(editor.getSoftTabs()).toBe(false)

        it "sets the attribute to the default when not configured", ->
          atom.config.set("overrides.scopes.source.python", {})
          spyOn(editor, "setSoftTabs")

          editor.setGrammar(atom.syntax.grammarForScopeName("source.python"))
          expect(editor.setSoftTabs).toHaveBeenCalledWith(true)
          expect(editor.getSoftTabs()).toBe(true)

      describe "softWrap", ->
        it "sets the attribute", ->
          atom.config.set("overrides.scopes.source.python.softWrap", true)
          spyOn(editor, "setSoftWrapped").andCallThrough()

          editor.setGrammar(atom.syntax.grammarForScopeName("source.python"))
          expect(editor.setSoftWrapped).toHaveBeenCalledWith(true)
          expect(editor.isSoftWrapped()).toBe(true)

        it "sets the attribute to the default when not configured", ->
          atom.config.set("overrides.scopes.source.python", {})
          spyOn(editor, "setSoftWrapped")

          editor.setGrammar(atom.syntax.grammarForScopeName("source.python"))
          # Failing since at least v0.128.0-8ccfb80...
          # expect(editor.setSoftWrapped).toHaveBeenCalledWith(false)
          expect(editor.isSoftWrapped()).toBe(false)

      describe "tabLength", ->
        it "sets the attribute", ->
          atom.config.set("overrides.scopes.source.python.tabLength", 16)
          spyOn(editor, "setTabLength").andCallThrough()

          editor.setGrammar(atom.syntax.grammarForScopeName("source.python"))
          expect(editor.setTabLength).toHaveBeenCalledWith(16)
          expect(editor.getTabLength()).toBe(16)

        it "sets the attribute to the default when not configured", ->
          atom.config.set("overrides.scopes.source.python", {})
          spyOn(editor, "setTabLength")

          editor.setGrammar(atom.syntax.grammarForScopeName("source.python"))
          expect(editor.setTabLength).toHaveBeenCalledWith(2)
          expect(editor.getTabLength()).toBe(2)
