fs = require "fs-plus"
path = require "path"
temp = require "temp"
wrench = require "wrench"

{WorkspaceView} = require "atom"
Overrides = require "../lib/overrides"

describe "Overrides", ->
  [buffer, editor, tempPath] = []

  getConfigFilePath = (fileName) ->
    path.join(atom.getConfigDirPath(), fileName)

  beforeEach ->
    fixturesPath = atom.project.getPath()
    tempPath = fs.realpathSync(temp.mkdirSync("atom-overrides"))
    wrench.copyDirSyncRecursive(fixturesPath, tempPath, forceDelete: true)
    atom.project.setPath(tempPath)

    atom.workspaceView = new WorkspaceView()
    atom.workspace = atom.workspaceView.model

    atom.config.set("editor.tabLength", 2)

    filePath = path.join(tempPath, "atom-overrides.rb")
    fs.writeFileSync(filePath, "")
    waitsForPromise ->
      atom.workspaceView.open(filePath).then (e) ->
        editor = e
        buffer = editor.getBuffer()

    waitsForPromise ->
      atom.packages.activatePackage("overrides")

    waitsForPromise ->
      atom.packages.activatePackage("language-ruby")

    waitsForPromise ->
      atom.packages.activatePackage("language-python")

    spyOn(atom, "getConfigDirPath").andReturn(path.join(tempPath, "config"))

  describe "Overrides", ->
    it "respects the defaults", ->
      editor.insertText("if foo\n5\nend")
      editor.autoIndentBufferRow(1)
      expect(buffer.lineForRow(1)).toBe "  5"

    it "can override the defaults", ->
      filePath = path.join(tempPath, "atom-overrides.py")
      fs.writeFileSync(filePath, "")

      waitsForPromise ->
        atom.workspaceView.open(filePath).then (e) ->
          editor = e
          buffer = editor.getBuffer()

      runs ->
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

  describe "loadOverrides", ->
    it "returns nothing when given a path to a file that does not exist", ->
      filePath = "bad/path/redux.cson"
      overrides = Overrides.loadOverrides(filePath)
      expect(overrides).toBeNull()

    it "loads and returns the expected overrides", ->
      filePath = getConfigFilePath("overrides.cson")
      overrides = Overrides.loadOverrides(filePath)
      expect(overrides.source.python.tabLength).toBe(4)
      expect(overrides.source.python.softTabs).toBe(true)

  describe "watchOverridesFile", ->
    it "does nothing when the file does not exist", ->
      badFilePath = "bad/path/redux.cson"
      result = Overrides.watchOverridesFile(badFilePath)
      expect(result).toBeFalsy()

    it "watches the file for changes", ->
      filePath = Overrides.getOverridesFilePath()
      result = Overrides.watchOverridesFile(filePath)
      expect(result).toBeTruthy()

  describe "getOverridesFilePath", ->
    it "returns the expected file path", ->
      expectedFilePath = getConfigFilePath("overrides.cson")
      filePath = Overrides.getOverridesFilePath()
      expect(filePath).toEqual(expectedFilePath)
