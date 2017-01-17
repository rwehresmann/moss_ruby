MOSS-RUBY
========
Ruby gem to submit files to MOSS.

###What is Moss?
Moss (for a Measure Of Software Similarity) is an automatic system for determining the similarity of programs. To date, the main application of Moss has been in detecting plagiarism in programming classes. Since its development in 1994, Moss has been very effective in this role. The algorithm behind moss is a significant improvement over other cheating detection algorithms (at least, over those known to us).

More about [MOSS](http://theory.stanford.edu/~aiken/moss/)

###Supported Languages
C, C++, Java, C#, Python, Visual Basic, Javascript, FORTRAN, ML, Haskell, Lisp, Scheme, Pascal, Modula2, Ada, Perl, TCL, Matlab, VHDL, Verilog, Spice, MIPS assembly, a8086 assembly, a8086 assembly, MIPS assembly, HCL2.

###Requirements
* MOSS Account - [register](http://theory.stanford.edu/~aiken/moss/)

###Usage
Usage involves the following steps:

* Install gem
* Create a MossRuby object using your MOSS user id.
* Configure MOSS options on your MossRuby object
* Create a dictionary with the file details to check
* Call check on the MossRuby object to post the files to the server for processing. The response is the URL of the results.
* Optionally, call extract_results on the MossRuby object to get a Ruby dictionary (hash) containing the list of matches.


```
#!bash

gem install moss-ruby
```


```
#!ruby

require 'moss_ruby'

# Create the MossRuby object
moss = MossRuby.new(000000000) #replace 000000000 with your user id

# Set options  -- the options will already have these default values
moss.options[:max_matches] = 10
moss.options[:directory_submission] =  false
moss.options[:show_num_matches] = 250
moss.options[:experimental_server] =    false
moss.options[:comment] = ""
moss.options[:language] = "c"

# Create a file hash, with the files to be processed
to_check = MossRuby.empty_file_hash
MossRuby.add_file(to_check, "The/Files/Path/MyFile.c")
MossRuby.add_file(to_check, "Other/Files/Path/*.c")
MossRuby.add_file(to_check, "Many/Files/Paths/**/*.h")

# Get server to process files
url = moss.check to_check

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


###Licence
The MIT License (MIT)

Copyright (c) 2014 Andrew Cain
