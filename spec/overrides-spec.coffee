Overrides = require "../lib/overrides"

allOverrides = {
  'source.python':
    'tabLength': 4
    'softTabs': true

  'text':
    'tabLength': 2
    'softTabs': true

  'text.foo.bar':
    'tabLength': 16

  'text.foo':
    'softTabs': false
    'tabLength': 8
}

describe "Overrides", ->
  beforeEach ->
    Overrides.activate()  # TODO: Dirty hack. Fix ASAP!
    atom.config.set("overrides.scopes", allOverrides)

  describe "getOverrides", ->
    it "returns all configured overrides", ->
      overrides = Overrides.getOverrides()
      expect(overrides).toEqual(allOverrides)

  describe "getOverridesForScope", ->
    it "returns nothing when given a scope with no overrides", ->
      overrides = Overrides.getOverridesForScope("foo")
      expect(overrides).toEqual {}

    it "returns the expected overrides for the given non-cascading scope", ->
      overrides = Overrides.getOverridesForScope("source.python")
      expect(overrides).toEqual {
        'tabLength': 4
        'softTabs': true
      }

    it "returns the cascaded overrides for the given scope", ->
      overrides = Overrides.getOverridesForScope("text.foo.bar")
      expect(overrides).toEqual {
        'tabLength': 16
        'softTabs': false
      }
