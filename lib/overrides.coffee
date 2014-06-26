_ = require "underscore-plus"
clipboard = require "clipboard"

{Subscriber} = require "emissary"

module.exports =
  configDefaults:
    scopes: null

  activate: ->
    @subscriber = new Subscriber()

    @watchScopeConfig()

    @subscriber.subscribe atom.workspace.eachEditor (editor) =>
      @applyOverrides(editor)
      @handleEvents(editor)

    atom.workspaceView.command "overrides:copy-grammar-scope", =>
      @copyCurrentGrammarScope()

  handleEvents: (editor) ->
    @subscriber.subscribe editor, "grammar-changed", =>
      @applyOverrides(editor)

    @subscriber.subscribe editor, "destroyed", =>
      @subscriber.unsubscribe(editor)

  applyOverrides: (editor) ->
    grammar = editor.getGrammar()
    scopeName = grammar.scopeName
    overrides = @getOverridesForScope(scopeName)

    # TODO: Change the current implementation to something more flexible.
    for key in Object.getOwnPropertyNames(overrides)
      value = overrides[key]
      switch key
        when "tabLength"
          editor.setTabLength(value)
        when "softTabs"
          editor.setSoftTabs(value)
        when "softWrap"
          editor.setSoftWrap(value)

  getOverridesForScope: (scopeName) ->
    overrides = {}
    allOverrides = @getOverrides()
    return overrides unless allOverrides?

    scopeName?.split(".").reduce (previousScope, segment) =>
      scope = if previousScope then "#{previousScope}.#{segment}" else segment
      overrides = _.extend(overrides, allOverrides?[scope])
      scope
    , null # Ugh...

    overrides

  getOverrides: ->
    atom.config.get("overrides.scopes")

  watchScopeConfig: ->
    @subscriber.subscribe atom.config.observe "overrides.scopes", =>
      for editor in atom.workspace.getEditors()
        @applyOverrides(editor)

  copyCurrentGrammarScope: ->
    editor = atom.workspace.getActiveEditor()
    grammar = editor?.getGrammar()
    scopeName = grammar?.scopeName
    clipboard.writeText(scopeName)

  deactivate: ->
    @subscriber?.unsubscribe()
    @subscriber = null
