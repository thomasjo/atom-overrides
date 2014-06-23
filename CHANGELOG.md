## 0.4.0
* Added support for overriding soft wrap setting.

## 0.3.0
* Added first implementation of cascading overrides based on incremental scopes.

## 0.2.0
* Introduced a menu item for opening your overrides file.
* Renamed redux.cson -> overrides.cson.
* Added a few negative and positive tests.
* Implemented some simple error handling for dealing with parsing errors caused
  by an invalid overrides.cson file.

## 0.1.0 - First Release
* Naïve scope matching; scope name needs to match exactly in this release.
* Configuration file is monitored for changes, and changes are applied to all
  current editors.
* Supported editor settings are `tabLength` and `softTabs`.
  Don't worry, more will be added soon.
* Bugs are highly likely to exist; please report them in as much detail as
  possible.
