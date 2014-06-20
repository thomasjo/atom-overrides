fs = require "fs-plus"
path = require "path"
CSON = require "season"

{Subscriber} = require "emissary"

module.exports =
  activate: ->
    @subscriber = new Subscriber()

    overridesFilePath = @getOverridesFilePath()
    @loadOverrides(overridesFilePath)
    @watchOverridesFile(overridesFilePath)

    @subscriber.subscribe atom.workspace.eachEditor (editor) =>
      @applyOverrides(editor)
      @handleEvents(editor)

  handleEvents: (editor) ->
    @subscriber.subscribe editor, "grammar-changed", =>
      @applyOverrides(editor)

    @subscriber.subscribe editor, "destroyed", =>
      @subscriber.unsubscribe(editor)

  applyOverrides: (editor) ->
    grammar = editor.getGrammar()
    scopeName = grammar.scopeName
    overrides = @getScopeOverrides(scopeName)
    return unless overrides

    # TODO: Change the current implementation to something more flexible.
    for key in Object.getOwnPropertyNames(overrides)
      value = overrides[key]
      switch key
        when "tabLength"
          editor.setTabLength(value)
        when "softTabs"
          editor.setSoftTabs(value)

  getScopeOverrides: (scopeName) ->
    # TODO: Implement support for cascading scopes.
    @allOverrides?[scopeName] || null

  loadOverrides: (path) ->
    return null unless fs.existsSync(path)
    @allOverrides = CSON.readFileSync(path)

  watchOverridesFile: (path) ->
    # TODO: Handle file not existing by watching config dir?
    return false unless fs.existsSync(path)

    fs.watch path, (event) =>
      return unless event == "change"
      @loadOverrides(path)
      for editor in atom.workspace.getEditors()
        @applyOverrides(editor)

    return true

  getOverridesFilePath: ->
    # TODO: Make this configurable?
    path.join(atom.getConfigDirPath(), "redux.cson")

  deactivate: ->
    @subscriber?.unsubscribe()
    @subscriber = null
