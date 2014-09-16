_ = require "underscore-plus"
clipboard = require "clipboard"

{Subscriber} = require "emissary"

# Public: Handles all overrides functionality.
class Overrides
  Subscriber.includeInto(this)

  configDefaults:
    scopes: null

  constructor: ->
    @map =
      showIndentGuide: (editorView, value) -> editorView.setShowIndentGuide(value)
      showInvisibles: (editorView, value) ->
        editorView.getEditor().displayBuffer.setInvisibles(value)
      softTabs: (editorView, value) -> editorView.getEditor().setSoftTabs(value)
      softWrap: (editorView, value) -> editorView.getEditor().setSoftWrap(value)
      tabLength: (editorView, value) -> editorView.getEditor().setTabLength(value)

    @whitelist = Object.keys(@map)

  # Public: Activates the package.
  activate: ->
    @watchConfig()

    atom.workspaceView.eachEditorView (editorView) =>
      @applyOverrides(editorView)
      @handleEvents(editorView)

    atom.workspaceView.command "overrides:copy-grammar-scope", =>
      @copyCurrentGrammarScope()

  # Public: Deactivates the package.
  deactivate: ->
    @unsubscribe()

  # Internal: Applies the default settings to the given view.
  #
  # editorView - {EditorView} to which to apply the defaults.
  applyDefaults: (editorView) ->
    @applySettings(editorView, @getDefaults())

  # Internal: Applies the appropriate overrides to the given view.
  #
  # editorView - {EditorView} to which to apply the overrides.
  applyOverrides: (editorView) ->
    scopeName = @getGrammarScopeName(editorView)
    @applySettings(editorView, @getOverridesForScope(scopeName))

  # Internal: Applies the settings to the view.
  #
  # editorView - {EditorView} to which to apply the settings.
  # settings - Settings to apply.
  applySettings: (editorView, settings) ->
    for func, value of settings
      @map[func]?(editorView, value)

  # Internal: Copies the current scope to the clipboard.
  copyCurrentGrammarScope: ->
    scopeName = @getGrammarScopeName(atom.workspace.getActiveEditor())
    clipboard.writeText(scopeName)

  # Internal: Gets the user's default editor configuration settings.
  #
  # Returns the default settings.
  getDefaults: ->
    _.defaults(atom.config.get("editor"), atom.config.getDefault("editor"))

  # Gets the grammar's scope name for the given `EditorView`.
  #
  # editorView - {EditorView} for which to retrieve the grammar's scope name.
  #
  # Returns the grammar's scope name {String}.
  getGrammarScopeName: (editorView) ->
    editorView.getEditor()?.getGrammar()?.scopeName

  # Internal: Gets all overrides.
  #
  # Returns the overrides for all scopes.
  getOverrides: ->
    atom.config.get("overrides.scopes")

  # Internal: Gets the overrides for the given scope name.
  #
  # This method calculates the cascading settings in order to deliver all of
  # the settings for the given scope.
  #
  # scopeName - Scope name {String} to get the overrides for.
  #
  # Returns the overrides for only the given scope.
  getOverridesForScope: (scopeName) ->
    overrides = {}
    temp = @getOverrides()
    _.each scopeName?.split("."), (name) =>
      if temp?[name]?
        overrides = _.defaults(temp[name], overrides)
        overrides = _.pick(overrides, @whitelist)
        temp = temp[name]

    overrides

  # Internal: Sets up event handlers.
  #
  # editorView - {EditorView} upon which to place event handlers.
  handleEvents: (editorView) ->
    editor = editorView.getEditor()
    @subscribe editor, "destroyed", => @unsubscribe editor
    editor.onDidChangeGrammar =>
      @applyDefaults(editorView)
      @applyOverrides(editorView)

  # Internal: Subscribes to updates for the Atom configuration.
  watchConfig: () ->
    # Too greedy? We're surely handling too many updates, but the impact to
    # performance does not be justify implementing more complex logic at this
    # point in time...
    @subscribe atom.config, "updated", =>
      @applyOverrides(view) for view in atom.workspaceView.getEditorViews()

module.exports = new Overrides
