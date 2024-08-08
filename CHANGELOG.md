### 0.5.0

Restructure the gem completely:

- extract `FileSorter` (that can sort classes in a file) and a new `StringSorter` (that can sort classes in a string)
- clean up the code into their own modules / classes
- add a DSL for running the sorters from ruby code
- enhance the tests

**BREAKING CHANGE**: if you called the file sorter from ruby like this:

```ruby
TailwindSorter::Sorter.run(file_name, warn_only: true/false, config_file: "some_config")
```

you need to change the call to the new syntax:

```ruby
TailwindSorter.sort_file(file_name, warn_only: true/false, config_file: "some_config")

```

### 0.4.1

Add support for processing multiple files at once.

### 0.4.0

- Add support for regular expressions in configuration for class ordering (#3)

  So instead of having to specify all variants of a certain Tailwind class, now you can cover all of them with a
  regular expression.
- Cache sorting keys during processing (speeds up sorting a file with repeating CSS classes).
- Fix LOAD_PATH issues when running tests (#2).
- Add Github Action for tests, enhance tests.
- Require ruby 3.1+.

### 0.3.1

Return warnings when called from ruby code in warn_only mode.

### 0.3.0

First public release of the gemified version of Tailwind sorter.

### 0.0.0 - the original script

The repository with the bare-bones sorter script can be found here: https://github.com/NejRemeslnici/tailwind-sorter/tree/original-script
