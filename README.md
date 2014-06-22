# Editor Redux
An Atom package that provides support for overriding editor settings based on
grammar scopes.

## Installing
Use the Atom package manager and search for e.g. "editor redux", or run
`apm install editor-redux` from the command line.

## Usage
The quickest way to tweak your overrides is via the menu item _Open Your
Overrides_, which opens the overrides file. For the time being, the path to the
overrides file is hardcoded to `<atom-config-dir>/overrides.cson`.

### Cascading overrides
Overrides are applied in a cascading manner, based on incremental scope matches.
For instance, given the example file below, will override the tab length and
soft tabs settings to `4` and `true`, respectively, for a Python editor. Whereas
for e.g. a CoffeeScript editor (meaning a scope equal to `source.coffee`) only
the tab length will overridden, and it'll be set to `2`. In other words, ff we
remove the explicit override listed under `source.python`, we will inherit the
override from `source`.

### Example overrides file
```coffeescript
'source.python':
  'tabLength': 4
  'softTabs': true

`source`:
  `tabLength`: 2
```

The configuration file is monitored for changes, so there's no need to reload
Atom. Simply edit and save, and your changes will applied immediately.

## Status
Right now, the only supported editor settings are `tabLength` and `softTabs`.
Support for more overrides will be added as soon as possible.

## TODO
Current wish list, in a semi-prioritized order;

- [x] Add tests.
- [x] Menu item (or similar) for opening the configuration file.
- [x] Support cascading overrides based on incremental scope matching.
- [ ] Implement support for more editor related settings.
  - [ ] Find a more flexible system than the current `switch` nonsense...
  - [ ] Support for package specific settings for packages such as
    [Whitespace](https://github.com/atom/whitespace)
