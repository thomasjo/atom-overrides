_ = require "underscore-plus"
fs = require "fs-plus"
path = require "path"
CSON = require "season"

{Subscriber} = require "emissary"

class Overrides
  Subscriber.includeInto(this)

  activate: ->
    overridesFilePath = @getOverridesFilePath()
    @watchOverridesFile(overridesFilePath)

    atom.workspace.eachEditor (editor) =>
      @applyOverrides(editor)
      @handleEvents(editor)

    atom.workspaceView.command "overrides:open-user-overrides", ->
      atom.workspace.open(overridesFilePath)

  handleEvents: (editor) ->
    @subscribe editor, 'grammar-changed', =>
      @applyOverrides(editor)

    @subscribe editor, 'destroyed', =>
      @unsubscribe editor

  applyOverrides: (editor) ->
    grammar = editor.getGrammar()
    scopeName = grammar.scopeName
    overrides = @getScopeOverrides(scopeName)

    for key, value of overrides
      switch key
        when "tabLength"
          editor.setTabLength(value)
        when "softTabs"
          editor.setSoftTabs(value)
        when "softWrap"
          editor.setSoftWrap(value)

  getScopeOverrides: (scopeName) ->
    whitelist = ['softTabs', 'softWrap', 'tabLength']

    overrides = {}
    temp = @loadOverrides(@getOverridesFilePath())
    _.each scopeName?.split("."), (name) ->
      if temp?[name]?
        overrides = _.defaults(temp[name], overrides)
        overrides = _.pick(overrides, whitelist)
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
