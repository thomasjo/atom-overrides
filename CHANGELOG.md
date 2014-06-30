## 0.7.0
* Monitor configuration for all changes, and apply overrides when an update has
  been observed. Resolves problems outlined in issue
  [#3](https://github.com/thomasjo/atom-overrides/issues/3).

## 0.6.0
* Change to use a nested configuration that makes the inheritance more obvious.
* Migrate from `overrides.cson` file for configuration, to Atom's `config.cson`.
* Code has been cleaned up, and overall quality has been improved.

## 0.5.0
* Renamed the package from _Editor Redux_ to _Overrides_.

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
