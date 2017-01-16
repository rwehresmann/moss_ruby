$LOAD_PATH.unshift File.expand_path("../../lib", __FILE__)
require 'moss_ruby'
require 'webmock/rspec'

RSpec::Matchers.define :a_file_like do |filename, lang|
    match { |actual| /file [0-9]+ c [0-9]+ .*#{filename}\n/.match(actual) }
end

RSpec::Matchers.define :text_starting_with do |line|
    match { |actual| actual.start_with? line }
end

RSpec::Matchers.define :text_matching_pattern do |pattern|
  match { |actual| (actual =~ pattern) == 0 }
end
