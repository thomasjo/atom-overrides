fs = require "fs-plus"
path = require "path"
temp = require "temp"
wrench = require "wrench"

Overrides = require "../lib/overrides"

describe "Overrides", ->
  [tempPath] = []

  getConfigFilePath = (fileName) ->
    path.join(atom.getConfigDirPath(), fileName)

  beforeEach ->
    fixturesPath = atom.project.getPath()
    tempPath = fs.realpathSync(temp.mkdirSync("atom-overrides"))
    wrench.copyDirSyncRecursive(fixturesPath, tempPath, forceDelete: true)
    atom.project.setPath(tempPath)

    spyOn(atom, "getConfigDirPath").andReturn(path.join(tempPath, "config"))

  describe "getScopeOverrides", ->
    beforeEach ->
      filePath = getConfigFilePath("overrides.cson")
      Overrides.loadOverrides(filePath)

    it "returns nothing when given a scope with no overrides", ->
      overrides = Overrides.getScopeOverrides("foo")
      expect(overrides).toEqual {}

    it "returns the expected overrides for the given non-cascading scope", ->
      overrides = Overrides.getScopeOverrides("source.python")
      expect(overrides).toEqual {
        'tabLength': 4
        'softTabs': true
      }

    it "returns the cascaded overrides for the given scope", ->
      overrides = Overrides.getScopeOverrides("text.foo.bar")
      expect(overrides).toEqual {
        'tabLength': 16
        'softTabs': false
      }

  describe "loadOverrides", ->
    it "returns nothing when given a path to a file that does not exist", ->
      filePath = "bad/path/redux.cson"
      overrides = Overrides.loadOverrides(filePath)
      expect(overrides).toBeNull()

    it "loads and returns the expected overrides", ->
      filePath = getConfigFilePath("overrides.cson")
      overrides = Overrides.loadOverrides(filePath)
      expect(overrides["source.python"]).toBeDefined()

  describe "watchOverridesFile", ->
    it "does nothing when the file does not exist", ->
      badFilePath = "bad/path/redux.cson"
      result = Overrides.watchOverridesFile(badFilePath)
      expect(result).toEqual(false)

    it "watches the file for changes", ->
      filePath = Overrides.getOverridesFilePath()
      result = Overrides.watchOverridesFile(filePath)
      expect(result).toEqual(true)

  describe "getOverridesFilePath", ->
    it "returns the expected file path", ->
      expectedFilePath = getConfigFilePath("overrides.cson")
      filePath = Overrides.getOverridesFilePath()
      expect(filePath).toEqual(expectedFilePath)
