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
      softTabs: (editor, value) -> editor.setSoftTabs(value)
      softWrap: (editor, value) -> editor.setSoftWrapped(value)
      tabLength: (editor, value) -> editor.setTabLength(value)

    @whitelist = Object.keys(@map)

  # Public: Activates the package.
  activate: ->
    @watchConfig()

    @subscribe atom.workspace.onDidAddTextEditor (event) =>
      editor = event.textEditor
      @applyOverrides(editor)
      @handleEvents(editor)

    atom.workspaceView.command "overrides:copy-grammar-scope", =>
      @copyCurrentGrammarScope()

  # Public: Deactivates the package.
  deactivate: ->
    @unsubscribe()

  # Internal: Applies the default settings to the given editor.
  #
  # editor - {Editor} to which to apply the defaults.
  applyDefaults: (editor) ->
    @applySettings(editor, @getDefaults())

  # Internal: Applies the appropriate overrides to the given editor.
  #
  # editor - {Editor} to which to apply the overrides.
  applyOverrides: (editor) ->
    scopeName = @getGrammarScopeName(editor)
    @applySettings(editor, @getOverridesForScope(scopeName))

  # Internal: Applies the settings to the editor.
  #
  # editor - {Editor} to which to apply the settings.
  # settings - Settings to apply.
  applySettings: (editor, settings) ->
    for func, value of settings
      @map[func]?(editor, value)

  # Internal: Copies the current scope to the clipboard.
  copyCurrentGrammarScope: ->
    scopeName = @getGrammarScopeName(atom.workspace.getActiveEditor())
    clipboard.writeText(scopeName)

  # Internal: Gets the user's default editor configuration settings.
  #
  # Returns the default settings.
  getDefaults: ->
    _.defaults(atom.config.get("editor"), atom.config.getDefault("editor"))

  # Gets the grammar's scope name for the given `Editor`.
  #
  # editor - {Editor} for which to retrieve the grammar's scope name.
  #
  # Returns the grammar's scope name {String}.
  getGrammarScopeName: (editor) ->
    editor?.getGrammar()?.scopeName

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
  # editor - {Editor} upon which to place event handlers.
  handleEvents: (editor) ->
    @subscribe editor, "destroyed", => @unsubscribe editor
    @subscribe editor.onDidChangeGrammar =>
      @applyDefaults(editor)
      @applyOverrides(editor)

  # Internal: Subscribes to updates for the Atom configuration.
  watchConfig: () ->
    # Too greedy? We're surely handling too many updates, but the impact to
    # performance does not be justify implementing more complex logic at this
    # point in time...
    @subscribe atom.config.onDidChange =>
      @applyOverrides(editor) for editor in atom.workspace.getTextEditors()

module.exports = new Overrides
