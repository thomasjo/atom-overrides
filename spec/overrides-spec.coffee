fs = require "fs-plus"
path = require "path"
temp = require "temp"
wrench = require "wrench"

{WorkspaceView} = require "atom"
Overrides = require "../lib/overrides"

allOverrides = {
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
}

describe "Overrides", ->
  [buffer, editor, tempPath] = []

  beforeEach ->
    fixturesPath = atom.project.getPath()
    tempPath = fs.realpathSync(temp.mkdirSync("atom-overrides"))
    wrench.copyDirSyncRecursive(fixturesPath, tempPath, forceDelete: true)
    atom.project.setPath(tempPath)

    atom.workspaceView = new WorkspaceView()
    atom.workspace = atom.workspaceView.model

    filePath = path.join(tempPath, "atom-overrides.rb")
    fs.writeFileSync(filePath, "")
    editor = atom.workspaceView.openSync(filePath)
    buffer = editor.getBuffer()

    waitsForPromise ->
      atom.packages.activatePackage("overrides")
      atom.packages.activatePackage("language-ruby")
      atom.packages.activatePackage("language-python")

    atom.config.set("editor.tabLength", 2)
    atom.config.set("overrides.scopes", allOverrides)

  describe "Overrides", ->
    it "respects the defaults", ->
      editor.insertText("if foo\n5\nend")
      editor.autoIndentBufferRow(1)
      expect(buffer.lineForRow(1)).toBe "  5"

    it "can override the defaults", ->
      filePath = path.join(tempPath, "atom-overrides.py")
      fs.writeFileSync(filePath, "")
      editor = atom.workspaceView.openSync(filePath)
      buffer = editor.getBuffer()

      editor.insertText("if foo:\n5\n")
      editor.autoIndentBufferRow(1)
      expect(buffer.lineForRow(1)).toBe "    5"

    it "updates settings when the grammar is changed after the file is opened", ->
      editor.setGrammar(atom.syntax.grammarForScopeName("source.python"))
      editor.insertText("if foo:\n5\n")
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
