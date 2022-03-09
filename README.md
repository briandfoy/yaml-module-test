# Check a bunch of Perl YAML files

The collection of Perl modules that deal with YAML act differently or
implement different parts of the YAML spec. There are annoying
differences even among different versions of the same module.

I've been bit by this on more than a few projects. In some cases, I
needed to find an older module version that could parse the existing
data then export with module I want to use.

In an ideal world I'd just change the input to suit the tool, but I
don't always get to do that. I made this little program to figure out
which module/version works for the input. Once I know that, I can
specify the right prerequisites.

This program uses the included module distributions so it doesn't need
to download anything. Give it the file that you want to check:

	% perl yaml-test.pl some-file.yml

There are some example YAML files in *examples*.

## See also

* [YAML vs YAML::XS inconsistencies (YAML::Syck and YAML::Tiny too)](https://perlmaven.com/yaml-vs-yaml-xs-inconsistencies)
* [YAML Test Matrix Overview](https://matrix.yaml.info)


## Notes on versions

Some modules or versions aren't worth testing. You're unlikely to have
ever used these.

### YAML::PP

* Versions before 0.04 did not have `LoadFile`

### YAML::PP::LibYAML

* Never really made much progress as a serious module

### YAML::Tiny

* Versions before 1.04 did not have `LoadFile`, so I don't include those.
* Version 1.19 had an exporting problem, so I don't include that one

