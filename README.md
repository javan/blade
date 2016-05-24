# Blade
### A [Sprockets](https://github.com/rails/sprockets) Toolkit for Building and Testing JavaScript Libraries

## Getting Started

Add Blade to your `Gemfile`.

```ruby
source "https://rubygems.org"

gem 'blade'
```

Create a `.blade.yml` (or `blade.yml`) file in your project’s root, and define your Sprockets [load paths](https://github.com/rails/sprockets#the-load-path) and [logical paths](https://github.com/rails/sprockets#logical-paths). Example:

```yaml
# .blade.yml
load_paths:
  - src
  - test/src
  - test/vendor

logical_paths:
  - widget.js
  - test.js
```

## Compiling

Configure your build paths and [compressors](https://github.com/rails/sprockets#minifying-assets):

```yaml
# .blade.yml
…
build:
  logical_paths:
    - widget.js
  path: dist
  js_compressor: uglifier # Optional
```

Run `bundle exec blade build` to compile `dist/widget.js`.

## Testing Locally

By default, Blade sets up a test runner using [QUnit](http://qunitjs.com/) via the [blade-qunit_adapter](https://github.com/javan/blade-qunit_adapter) gem.

Run `bundle exec blade runner` to launch Blade’s test console and open the URL it displays in one or more browsers. Blade detects changes to your logical paths and automatically restarts the test suite.

![Blade Runner](https://cloud.githubusercontent.com/assets/5355/15481643/8aef7c98-20f9-11e6-9826-80a32ce7568c.png)

## Testing on CI

Run `bundle exec blade ci` to start Blade’s test console in non-interactive CI mode, and launch a browser pointed at Blade’s testing URL (usually http://localhost:9876). The process will return `0` on success and non-zero on failure.

To test on multiple browsers with [Sauce Labs](https://saucelabs.com/), see the [Sauce Labs plugin](https://github.com/javan/blade-sauce_labs_plugin).

## Projects Using Blade

* [Trix](https://github.com/basecamp/trix)
* [Turbolinks](https://github.com/turbolinks/turbolinks)
* [Action Cable](https://github.com/rails/rails/tree/master/actioncable)

---

Licensed under the [MIT License](LICENSE.txt)

© 2016 Javan Makhmali
