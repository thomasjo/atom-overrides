_ = require "underscore-plus"
clipboard = require "clipboard"

{Subscriber} = require "emissary"

class Overrides
  Subscriber.includeInto(this)

  configDefaults:
    scopes: null

  constructor: ->
    @map =
      showInvisibles: (editorView, value) -> editorView.setShowInvisibles(value)
      softTabs: (editorView, value) -> editorView.getEditor().setSoftTabs(value)
      softWrap: (editorView, value) -> editorView.getEditor().setSoftWrap(value)
      tabLength: (editorView, value) -> editorView.getEditor().setTabLength(value)

    @whitelist = Object.keys(@map)

  activate: ->
    @watchConfig()

    atom.workspaceView.eachEditorView (editorView) =>
      @applyOverrides(editorView)
      @handleEvents(editorView)

    atom.workspaceView.command "overrides:copy-grammar-scope", =>
      @copyCurrentGrammarScope()

  handleEvents: (editorView) ->
    editor = editorView.getEditor()
    @subscribe editor, "grammar-changed", => @applyOverrides(editorView)
    @subscribe editor, "destroyed", => @unsubscribe editor

  applyOverrides: (editorView) ->
    editor = editorView.getEditor()
    grammar = editor.getGrammar()
    scopeName = grammar.scopeName
    overrides = @getOverridesForScope(scopeName)

    for func, value of overrides
      @map[func](editorView, value)

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
      @applyOverrides(view) for view in atom.workspaceView.getEditorViews()

  copyCurrentGrammarScope: ->
    editor = atom.workspace.getActiveEditor()
    grammar = editor?.getGrammar()
    scopeName = grammar?.scopeName
    clipboard.writeText(scopeName)

  deactivate: ->
    @unsubscribe()

module.exports = new Overrides
