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

Until the scope cascade feature has been implemented, the scope name of the
grammar you wish to override editor settings for needs to be an exact match.
In other words, if you wish to override indentation settings for Python code,
you need to add an entry for `source.python` to your overrides file.

### Example overrides file
```coffeescript
'source.python':
  'tabLength': 4
  'softTabs': true
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
- [ ] Support cascading overrides based on incremental scope matching.
- [ ] Implement support for more editor related settings.
  - [ ] Find a more flexible system than the current `switch` nonsense...
  - [ ] Support for package specific settings for packages such as
    [Whitespace](https://github.com/atom/whitespace)
