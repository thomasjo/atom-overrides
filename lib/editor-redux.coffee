_ = require "underscore-plus"
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

    atom.workspaceView.command "editor-redux:open-user-overrides", =>
      @openOverridesFile(overridesFilePath)

  handleEvents: (editor) ->
    @subscriber.subscribe editor, "grammar-changed", =>
      @applyOverrides(editor)

    @subscriber.subscribe editor, "destroyed", =>
      @subscriber.unsubscribe(editor)

  applyOverrides: (editor) ->
    grammar = editor.getGrammar()
    scopeName = grammar.scopeName
    overrides = @getScopeOverrides(scopeName)

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

  getScopeOverrides: (scopeName) ->
    overrides = {}
    scopeName?.split(".").reduce (previousScope, segment) =>
      scope = if previousScope then "#{previousScope}.#{segment}" else segment
      overrides = _.extend(overrides, @allOverrides?[scope])
      scope
    , null # Ugh...

    overrides

  loadOverrides: (path) ->
    return null unless fs.existsSync(path)

    try
      # TODO: Drop the instance variable and only return the object?
      @allOverrides = CSON.readFileSync(path)
    catch
      console.error "An error occured while parsing overrides.cson"
    finally
      return @allOverrides

  watchOverridesFile: (path) ->
    # TODO: Handle file not existing by watching config dir?
    return false unless fs.existsSync(path)

    fs.watch path, (event) =>
      return unless event == "change"
      @loadOverrides(path)
      for editor in atom.workspace.getEditors()
        @applyOverrides(editor)

    return true

  openOverridesFile: (path) ->
    atom.workspace.open(path)

  getOverridesFilePath: ->
    # TODO: Make this configurable?
    path.join(atom.getConfigDirPath(), "overrides.cson")

  deactivate: ->
    @subscriber?.unsubscribe()
    @subscriber = null
