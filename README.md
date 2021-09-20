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
Tailwind, sorters operating over a huge static list of "default" pre-ordered classes are becoming less useful as each
developer will inevitably come to their **own unique set of classes** making it almost impossible to hard-wire a common
solution. This problem is even larger if you’ve added
[custom utility classes](https://tailwindcss.com/docs/adding-new-utilities) to your project.

Above all, it is **surprisingly easy** to create a custom sorting script – the one we use and present here is only
~110 lines. So, take this script and config as a **template for you to revise and adopt**.

## Installation

Just grab the two files from
here: [`tailwind_sorter.rb`](https://github.com/NejRemeslnici/tailwind-sorter/blob/main/bin/tailwind_sorter.rb) is the
executable ruby script
and [`tailwind_sorter.yml`](https://github.com/NejRemeslnici/tailwind-sorter/blob/main/config/tailwind_sorter.yml) is
its configuration file. By default, the configuration file is expected to reside in the `config` directory but this can
be [tweaked in the script](https://github.com/NejRemeslnici/tailwind-sorter/blob/main/bin/tailwind_sorter.rb#L94).

The script has **no dependencies**, apart from ruby (tested on ruby 2.6+) and its stdlib.

There are currently **no plans to make this a gem** as the code and especially the configuration is expected to be
customized to fully suit your needs and we are not ready to support a generic tool with defaults for everyone.

## Configuration

Without customizing, the script will – somehow – work but its full potential will be available only when properly
configured.

There are two important places to configure in the YAML file:

- **regular expressions** to match the classes in your files: out of the box, the script matches classes in the Slim
  format (such as `section#flash-messages.hidden.mt-4`) and classes in the context of the `class` attribute in ruby /
  Rails helpers (`link_to "E-shop", eshop_path, class: "no-underline font-bold red-100")`,

- **CSS classes order and grouping**: the `classes_order` section in the YAML file determines the order in which the
  classes will be sorted. If you want the classes with Tailwind variants (such as `sm:`, `hover:` etc.) to always be
  ordered towards the end of line, put the classes in one big group, otherwise split them into any groups you want and
  they will be ordered last in the particular group.

Unknown (i.e. custom) classes will be **ordered first by default**. If you want them ordered last, replace
the [`default_index`](https://github.com/NejRemeslnici/tailwind-sorter/blob/main/bin/tailwind_sorter.rb#L20) parameter
in the script with a big-enough number. We recommend ordering custom classes first though as in our opinion such classes
usually bear more important meanings than the Tailwind ones and this setup also makes it easier to spot typos in class
names.

The default sort order of the classes resembles the one of Headwind which, in turn, seems to be inspired by the order of
the sections in the [official Tailwind documentation](https://tailwindcss.com/docs).

### Adding your unique set of Tailwind classes

The script works best if you only include the classes that you really use in your project. Once you grab all the classes
e.g. from your production CSS bundle, you can partially reorder them e.g. using the following ruby snippet. Suppose you
have the ”default“ classes sorted, on per line, in the `default_classes.txt` file and your own (unordered) classes
in `our_classes.txt`. Then:

```ruby
head = File.readlines("default_classes.txt").map(&:strip)
our = File.readlines("our_classes.txt").map(&:strip)
sorted_classes = our.sort_by { |word| head.index(word) || 10_000 }
File.open("sorted_classes.txt", "w") { |f| f.write(sorted_classes.join("\n")) }
```

Then, you can grab these sorted classes, update the position of your own classes (you’ll find them near the end of
the `sorted_classes.txt` file) and move all of them to the appropriate sections of the YAML config file.

## Running the script

Of course, you can run the script manually, like so:

```sh
bin/tailwind_sorter.rb app/views/my_template.html.slim
```

The script finds all css classes and reorders them in-place in the file.

You can also reorder classes in all templates in your project:

```sh
find ./ -name '*.slim' -exec bin/tailwind_sorter.rb {} \;
```

## Running automatically via your IDE / editor

Perhaps the best way to run the script is using your editor or IDE. Many editors provide the possibility to watch your
edited files and **run arbitrary command when they are changed / saved**.

We use Tailwind sorter this way, the script is triggered by ”file watchers“ configured in RubyMine and it works great.
Have a look at the wiki for a guide to set up such integration.

## Guarding sort order via Overcommit

We use [Overcommit](https://github.com/sds/overcommit) to guard a common set of rules configured in our project upon
each commit. Here, we provide
a [simple pre-commit hook](https://github.com/NejRemeslnici/tailwind-sorter/blob/main/.git-hooks/pre_commit/check_css_classes_order.rb)
and a sample
[configuration in the `.overcommit.yml` file](https://github.com/NejRemeslnici/tailwind-sorter/blob/main/.overcommit.yml#L31)
. The hook calls Tailwind sorter with the `-w` argument, asking it to not change the file but only print the ordering
problems found.

## Running tests

```sh
bundle install # to install the rspec gem
bundle exec rspec
.............

Finished in 0.34583 seconds (files took 0.07635 seconds to load)
13 examples, 0 failures
```

## Answers for the curious

### But I heard ruby is slow. Is this fast enough?

When we initially reordered CSS classes in all our templates (~900 Slim files) with the script changing nearly 4000
lines, the whole process took less than 30 seconds. This makes the processing speed of approximately 30 files per
second. Judge for yourself if this is fast enough for your needs or not.
