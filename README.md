# Tailwind sorter

**A ruby script to sort the [Tailwind CSS](https://tailwindcss.com) classes in your templates _the custom way_.**

The script is a standalone command that can work in two ways:

- it can edit the given file in place or
- it can just generate warning messages suitable for [Overcommit](https://github.com/sds/overcommit),
  [Lefthook](https://github.com/evilmartians/lefthook) or any other similar system (or people, if that’s what you
  prefer).

Out of the box the script supports sorting classes in [Slim templates](http://slim-lang.com/) but can be configured for
anything else.

Please read the article on dev.to for all details, if interested.

## Why?

We are aware of the other good solutions to sorting Tailwind classes but we’ve hit some limit in each of them:

- [Headwind](https://github.com/heybourn/headwind) is VS Code-only but we needed something in RubyMine and Overcommit,
  too.
- There are ports to the environments we need
  ([Tailwind Formatter](https://plugins.jetbrains.com/plugin/13376-tailwind-formatter/) JetBrains plugin,
  [RustyWind](https://github.com/avencera/rustywind) CLI tool) but none of these fully suit our needs, especially since
  we use [Slim](http://slim-lang.com/) templates in our project and need different regexps to search for the classes.
  Also, we like to sort our Tailwind classes a bit differently than Headwind et al. default to.

In our opinion, especially since the [JIT mode](https://tailwindcss.com/docs/just-in-time-mode) has been introduced to
Tailwind, sorters operating over a huge static list of "default" classes are becoming less useful as each developer will
inevitably come to their **own unique set of classes** that is almost impossible to hard-wire.

Above all, it is **surprisingly easy** to create a custom sorting script – the one we use and present here is only
~110 lines. So, take this script and config as a **template for you to revise and amend**.

## Installation

Just grab the two files from
here: [`tailwind_sorter.rb`](https://github.com/NejRemeslnici/tailwind-sorter/blob/main/bin/tailwind_sorter.rb) is the
executable ruby script
and [`tailwind_sorter.yml`](https://github.com/NejRemeslnici/tailwind-sorter/blob/main/config/tailwind_sorter.yml) is
its configuration file. By default, the configuration file is expected to reside in the `config` directory but this can
be [tweaked in the script](https://github.com/NejRemeslnici/tailwind-sorter/blob/main/bin/tailwind_sorter.rb#L94).

The script has **no dependencies**, apart from ruby (tested on ruby 2.6+) and its stdlib.

There are currently no plans to make this a gem as the code and especially the configuration is expected to be
customized to fully suit your needs and we are not ready to support a generic tool with defaults for everyone.

## Configuration

Without customizing, the script will – somehow – work but its full potential will be used only when properly configured.

There are two important places to configure in the YAML file:

- **regular expressions** to match the classes in your files: out of the box, the script matches classes in the Slim
  format (`section#flash-messages.hidden.mt-4`) and classes in the context of the `class` attribute in ruby / Rails
  helpers (`link_to "E-shop", buy_path, class: "no-underline font-bold fg-red")`,
- **CSS classes order and grouping**: the `classes_order` section in the YAML file determines the order in which the
  classes will be sorted. If you want the Tailwind variants (such as `hover:` etc.) to always be ordered towards the end
  of line, put the classes in one big group, otherwise split them into any groups you need and they will be ordered last
  in the particular group.

Unknown (i.e. custom) classes will be **ordered first by default**. If you want them ordered last, replace
the [`default_index`](https://github.com/NejRemeslnici/tailwind-sorter/blob/main/bin/tailwind_sorter.rb#L20) parameter
in the script with a big-enough number.

The default sort order of the classes resembles the one of Headwind which, in turn, was inspired by the order of the 
sections in the [official Tailwind documentation](https://tailwindcss.com/docs).

### Using your unique set of Tailwind classes

The script works best if you only include the classes that you really use in your project. Once you grab all the classes 
e.g. from your production CSS bundle, you can partially reorder them e.g. using the following ruby snippet. Suppose you 
have the ”default“ classes, on per line, in the `default_classes.txt` file and your own classes set in `our_classes.txt`. Then:

```ruby
head = File.readlines("default_classes.txt").map(&:strip)
our = File.readlines("our_classes.txt").map(&:strip)
sorted_classes = our.sort_by { |word| head.index(word) || 10000 }
File.open("sorted_classes.txt", "w") { |f| f.write(sorted_classes.join("\n")) }
```

Then, you can grab these sorted classes, update the position of your own classes (you’ll find them near the end) and 
move them to the appropriate sections of the YAML config file. 

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
