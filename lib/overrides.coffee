_ = require "underscore-plus"
fs = require "fs-plus"
path = require "path"
CSON = require "season"

{Subscriber} = require "emissary"

class Overrides
  Subscriber.includeInto(this)

  constructor: ->
    @map =
      softTabs: (editor, value) ->
        editor.setSoftTabs(value)
      softWrap: (editor, value) ->
        editor.setSoftWrap(value)
      tabLength: (editor, value) ->
        editor.setTabLength(value)

    @whitelist = Object.keys(@map)

  activate: ->
    overridesFilePath = @getOverridesFilePath()
    @watchOverridesFile(overridesFilePath)

    atom.workspace.eachEditor (editor) =>
      @applyOverrides(editor)
      @handleEvents(editor)

    atom.workspaceView.command "overrides:open-user-overrides", ->
      atom.workspace.open(overridesFilePath)

  handleEvents: (editor) ->
    @subscribe editor, "grammar-changed", =>
      @applyOverrides(editor)

    @subscribe editor, "destroyed", =>
      @unsubscribe editor

  applyOverrides: (editor) ->
    grammar = editor.getGrammar()
    scopeName = grammar.scopeName
    overrides = @getScopeOverrides(scopeName)

    for func, value of overrides
      @map[func](editor, value)

  getScopeOverrides: (scopeName) ->
    overrides = {}
    temp = @loadOverrides(@getOverridesFilePath())
    _.each scopeName?.split("."), (name) =>
      if temp?[name]?
        overrides = _.defaults(temp[name], overrides)
        overrides = _.pick(overrides, @whitelist)
        temp = temp[name]

    overrides

  loadOverrides: (path) ->
    return null unless fs.existsSync(path)
    CSON.readFileSync(path)

  watchOverridesFile: (path) ->
    if fs.existsSync(path)
      fs.watch path, (event) =>
        return unless event is "change"
        @applyOverrides(editor) for editor in atom.workspace.getEditors()

  getOverridesFilePath: ->
    path.join(atom.getConfigDirPath(), "overrides.cson")

  deactivate: ->
    @unsubscribe()

module.exports = new Overrides()
