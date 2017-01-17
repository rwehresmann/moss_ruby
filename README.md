# Description

Ruby gem to submit files to [MOSS](https://theory.stanford.edu/~aiken/moss/).

# This is a fork!

Credits to [macite](https://bitbucket.org/macite/), who [developed and published this gem in his Bitbucket repository](https://bitbucket.org/macite/moss-ruby).

What this fork brings new:

  * The possibility to upload directly a string whit the source code content, as content to check or as base content too (for more information about what is a **base** content/file, please check the usage instructions in the original [script](http://moss.stanford.edu/general/scripts/mossnet));
  * **to_check** is a object to store a hash with the files to be analyzed, and now is treated as an instance object;
  * Methods to add file/content are now instance methods;
  * Moss class name changed to only **Moss** (rather than **MossRuby**);
  * Updated gem structure;
  * A bit of code refactoring in **check** method.

What follow below is the original README, where only the usage section is updated. **Please note**: is pointed as requirements the creation of a MOSS account, because the usage require a user_id. However, whit the specified user_id of usage example, you are able to access MOSS server without problems (MOSS is public to everyone, but it wasn't always so, and maybe this *requirement* isn't more, in fact, a requirement).

### What is Moss?

Moss (for a Measure Of Software Similarity) is an automatic system for determining the similarity of programs. To date, the main application of Moss has been in detecting plagiarism in programming classes. Since its development in 1994, Moss has been very effective in this role. The algorithm behind moss is a significant improvement over other cheating detection algorithms (at least, over those known to us).

More about [MOSS](http://theory.stanford.edu/~aiken/moss/)

### Supported Languages

C, C++, Java, C#, Python, Visual Basic, Javascript, FORTRAN, ML, Haskell, Lisp, Scheme, Pascal, Modula2, Ada, Perl, TCL, Matlab, VHDL, Verilog, Spice, MIPS assembly, a8086 assembly, a8086 assembly, MIPS assembly, HCL2.

### Requirements

* MOSS Account - [register](http://theory.stanford.edu/~aiken/moss/)

### Usage

Usage involves the following steps:

* Install gem
* Create a Moss object using your MOSS user id.
* Configure MOSS options on your MossRuby object
* Fill a dictionary with the file details to check
* Call check from the Moss object to post the files to the server for processing. The response is the URL of the results.
* Optionally, call extract_results on the Moss object to get a Ruby dictionary (hash) containing the list of matches.


```
#!bash

gem 'moss_ruby', git: 'https://github.com/rwehresmann/moss_ruby.git'
```

```
#!ruby

# Create the Moss object
moss = Moss.new(000000000) #replace 000000000 with your user id, if you have it

# Set options  -- the options will already have these default values
moss.options[:max_matches] = 10
moss.options[:directory_submission] =  false
moss.options[:show_num_matches] = 250
moss.options[:experimental_server] =    false
moss.options[:comment] = ""
moss.options[:language] = "c"

# Add files to compare
moss.add_file("The/Files/Path/MyFile.c")
moss.add_file("Other/Files/Path/*.c")
moss.add_file("Many/Files/Paths/**/*.h")

# Or even string contents
moss.add_content(IO.read("The/Files/Path/MyOtherFile.c"))

# Get server to process files
url = moss.check

# Get results
results = moss.extract_results url

# Use results
puts "Got results from #{url}"
results.each { |match|
    puts "----"
    match.each { |file|
        puts "#{file[:filename]} #{file[:pct]} #{file[:html]}"
    }
}

```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).
