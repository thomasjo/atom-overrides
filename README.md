# Overrides [![Build Status](https://travis-ci.org/thomasjo/atom-overrides.svg?branch=master)](https://travis-ci.org/thomasjo/atom-overrides)
An Atom package that provides support for overriding editor settings based on
grammar scopes.

## Installing
Use the Atom package manager and search for e.g. "overrides", or run
`apm install overrides` from the command line.

## Usage
The quickest way to tweak your overrides is via the menu item _Open Your
Config_. For the time being all configured overrides need to be declared under
the `overrides.scopes` key.

### Example configuration file
```coffeescript
'editor':
  'tabLength': 4
# [..]
'overrides':
  'scopes':  
    'source':
      'tabLength': 2

      'python':
        'tabLength': 4

      'git-config':
        'tabLength': 8
        'softTabs': false

      'gfm':
        'showIndentGuide': false

    'text':
      'softWrap': true
      'showInvisibles': false
# [..]
```

The configuration is monitored for changes, so there's no need to reload Atom.
Simply edit and save, and your changes will applied immediately to all open
editors, as well as any future ones.

In order to help you out a little bit with adding overrides, there's a menu item
listed under _Packages &rarr; Overrides_, called _Copy Grammar Scope of Active
Editor_, that copies the scope name of the currently active editor to your
clipboard.

### Cascading overrides
Overrides are applied in a cascading manner, based on incremental scope matches.
For instance, given the example file above, all _Python_ editors will have their
tab length set to `4`. Whereas e.g. a _Git Config_ editor, meaning a scope equal
to `source.git-config`, the tab length setting will be set to `8`, and the soft
tabs setting will be set to `false`. If we were to remove the override for tab
length listed under `source: python`, we would inherit that setting override
from `source`.

## Status
Right now, the supported overrides are
* `showInvisibles`
* `showIndentGuide`
* `softTabs`
* `softWrap`
* `tabLength`

Support for more overrides will be added as soon as possible.

## TODO
Current wish list, in a semi-prioritized order;

- [x] Add tests.
- [x] Menu item (or similar) for opening the configuration file.
- [x] Support cascading overrides based on incremental scope matching.
- [ ] Implement support for more editor related settings.
  - [x] Find a more flexible system than the current `switch` nonsense...
  - [ ] Support for package specific settings for packages such as
    [Whitespace](https://github.com/atom/whitespace)
