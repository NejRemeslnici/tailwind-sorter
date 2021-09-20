# Tailwind sorter

**A ruby script to sort the [Tailwind CSS](https://tailwindcss.com) classes in your templates the custom way.**

The script acts as a standalone command that can act in two regimes:

- it can edit the given file in place or
- it can just generate warning messages suitable to be processed by [Overcommit](https://github.com/sds/overcommit),
  [Lefthook](https://github.com/evilmartians/lefthook) or any other similar system (or people, if that’s what you
  prefer).

Out of the box the script supports sorting classes in [Slim templates](http://slim-lang.com/) but can be configured for
anything else.

Please read the article on dev.to for all details, if interested.

## Why?

We are aware of the other good solutions to sorting Tailwind classes but we’ve hit some limits in each of them:

- [Headwind](https://github.com/heybourn/headwind) is VS Code-only but we needed something in RubyMine and Overcommit,
  too.
- There are ports to other environments
  ([Tailwind Formatter](https://plugins.jetbrains.com/plugin/13376-tailwind-formatter/) JetBrains plugin,
  [RustyWind](https://github.com/avencera/rustywind) CLI tool) but none of these fully suit our needs, especially
  because we use [Slim](http://slim-lang.com/) templates in our project and need different regexps to search for the
  classes. Also, we like to sort our Tailwind classes a bit differently than Headwind et al. default to.

In our opinion, especially since the JIT mode has been introduced to Tailwind, the sorters operating over a huge static
list of "default" classes are becoming less useful as each developer will inevitably use their own unique set of
classes that is almost impossible to hard-wire.

Above all, it is **surprisingly easy** to create a custom sorting script – the one we use and present here is only
~110 lines.

## Installation

Just grab the two files from here: `tailwind_sorter.rb` is the executable ruby script and `tailwind_sorter.yml` is its
configuration file. By default, the configuration file is expected to reside in the `config` directory but this can be
tweaked in the script.

The script has no dependencies, apart from ruby (tested on ruby 2.6+) and its stdlib.

There are currently no plans to make this a gem as the code and especially the configuration is expected to be
customized to fully suit your needs.

## Configuration

Without customizing, the script will somehow work but its full potential will be used only when properly configured.

## Running tests

```sh
bundle install # to install the rspec gem
bundle exec rspec
.............

Finished in 0.34583 seconds (files took 0.07635 seconds to load)
13 examples, 0 failures
```

## But I heard ruby is slow. Is this fast enough?

When we initially reordered CSS classes in all our templates (~900 Slim files) with the script changing nearly 4000
lines, the whole process took less than 30 seconds. This makes the processing speed of approximately 30 files per
second. Judge for yourself if this is fast enough for your needs or not.
