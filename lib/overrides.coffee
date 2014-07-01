_ = require "underscore-plus"
clipboard = require "clipboard"

{Subscriber} = require "emissary"

class Overrides
  Subscriber.includeInto(this)

  configDefaults:
    scopes: null

  constructor: ->
    @map =
      softTabs: (editor, value) -> editor.setSoftTabs(value)
      softWrap: (editor, value) -> editor.setSoftWrap(value)
      tabLength: (editor, value) -> editor.setTabLength(value)

    @whitelist = Object.keys(@map)

  activate: ->
    @watchConfig()

    atom.workspace.eachEditor (editor) =>
      @applyOverrides(editor)
      @handleEvents(editor)

    atom.workspaceView.command "overrides:copy-grammar-scope", =>
      @copyCurrentGrammarScope()

  handleEvents: (editor) ->
    @subscribe editor, "grammar-changed", => @applyOverrides(editor)
    @subscribe editor, "destroyed", => @unsubscribe editor

  applyOverrides: (editor) ->
    grammar = editor.getGrammar()
    scopeName = grammar.scopeName
    overrides = @getOverridesForScope(scopeName)

    for func, value of overrides
      @map[func](editor, value)

  getOverridesForScope: (scopeName) ->
    overrides = {}
    temp = @getOverrides()
    _.each scopeName?.split("."), (name) =>
      if temp?[name]?
        overrides = _.defaults(temp[name], overrides)
        overrides = _.pick(overrides, @whitelist)
        temp = temp[name]

    overrides

  getOverrides: ->
    atom.config.get("overrides.scopes")

  watchConfig: () ->
    # Too greedy? We're surely handling too many updates, but the impact to
    # performance does not be justify implementing more complex logic at this
    # point in time...
    @subscribe atom.config, "updated", =>
      @applyOverrides(editor) for editor in atom.workspace.getEditors()

  copyCurrentGrammarScope: ->
    editor = atom.workspace.getActiveEditor()
    grammar = editor?.getGrammar()
    scopeName = grammar?.scopeName
    clipboard.writeText(scopeName)

  deactivate: ->
    @unsubscribe()

module.exports = new Overrides()
