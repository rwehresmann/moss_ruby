# The MIT License (MIT)
#
# Copyright (c) 2014 Andrew Cain
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

require 'socket'
require 'open-uri'

class Moss
	attr_accessor   :userid
	attr_accessor   :server
	attr_accessor   :port
	attr_reader     :options

	def self.empty_data_hash
		{ base_files: [], files: [], base_contents: [], contents: [] }
	end

	def self.add_base_file ( hash, file )
		hash[:base_files] << file
	end

	def self.add_file ( hash, file )
		hash[:files] << file
	end

	def initialize(userid, server = "moss.stanford.edu", port = 7690)
		@options = {
			max_matches:            10,
			directory_submission:   false,
			show_num_matches:       250,
			experimental_server:    false,
			comment:                "",
			language:               "c"
		}
		@server = server
		@port = port
		@userid = userid
	end

	def upload(moss_server, to_upload, id = 0, option = { is_file: true })
		if option[:is_file]
			filename = to_upload.strip.encode('UTF-8', invalid: :replace, undef: :replace, replace: '').gsub /[^\w\-\/.]/, '_'
			content = IO.read(to_upload)
		else
			filename = (0...15).map { ('a'..'z').to_a[rand(26)] }.join
			content = to_upload
		end

		size = content.size

		if size > 0
			moss_server.write "file #{id} #{@options[:language]} #{size} #{filename}\n"
			moss_server.write content
		end
	end

	def check(to_check, callback = nil)
		return if to_check[:files].length == 0 && to_check[:content] == 0
		locate_files(to_check[:base_files] + to_check[:files])

		callback.call('Connecting to MOSS') unless callback.nil?
		moss_server = open_connection

		begin
			callback.call(' - Sending configuration details') unless callback.nil?
			send_header(moss_server)

			processing = to_check[:base_files]
			processing.each.inject(1) do |bf_count, file_search|
				callback.call(" - Sending base files #{bf_count} of #{processing.count} - #{file_search}") unless callback.nil?
				files = Dir.glob(file_search)
				files.each.inject(1) do |file_count, file|
					callback.call("   - Base file #{file_count} of #{files.count} - #{file}") unless callback.nil?
					upload moss_server, file
					file_count += 1
				end
				bf_count += 1
			end

			processing = to_check[:base_contents]
			processing.each.inject(1) do |count, content_search|
				callback.call("   - Sending base content #{count} of #{processing.count}") unless callback.nil?
				upload(moss_server, content_search, 0, is_file: false)
				count += 1
			end

			processing = to_check[:files]
			processing.each.inject(1) do |count, file_search|
				callback.call(" - Sending files #{count} of #{processing.count} - #{file_search}") unless callback.nil?
				files = Dir.glob(file_search)

				files.each.inject(1) do |file_count, file|
					callback.call("   - File #{file_count} of #{files.count} - #{file}") unless callback.nil?
					upload moss_server, file, file_count
					file_count += 1
				end
				count += 1
			end

			processing = to_check[:contents]
			processing.each.inject(1) do |count, content_search|
				callback.call("   - Sending base content #{count} of #{processing.count}") unless callback.nil?
				upload(moss_server, content_search, count, is_file: false)
				count += 1
			end

			callback.call(" - Waiting for server response") unless callback.nil?
			moss_server.write "query 0 #{@options[:comment]}\n"

			result = moss_server.gets

			moss_server.write "end\n"
			return result.strip
		ensure
			moss_server.close
		end
	end

	def extract_results(uri, min_pct = 10, callback = nil)
		result = Array.new
		begin
			match = -1
			match_file = Array.new
			data = Array.new
			to_fetch = get_matches(uri, min_pct, callback)
			to_fetch.each do |id|
				match += 1
				callback.call("Checking match #{match + 1} (id #{id})") unless callback.nil?

				# read the two match files
				match_url = "#{uri}/match#{id}-top.html"
				match_top = open(match_url).read().encode('UTF-8', 'binary', invalid: :replace, undef: :replace, replace: '?')

				callback.call(" - checking match #{match} percents") unless callback.nil?
				top = read_pcts match_top

				next if Integer(top[:pct0]) < min_pct && Integer(top[:pct1]) < min_pct

				callback.call(" - fetching #{match} html") unless callback.nil?

				match_file[0] = open("#{uri}/match#{id}-0.html").read().encode('UTF-8', 'binary', invalid: :replace, undef: :replace, replace: '?')
				match_file[1] = open("#{uri}/match#{id}-1.html").read().encode('UTF-8', 'binary', invalid: :replace, undef: :replace, replace: '?')

				# puts match_top
				# puts "---FILE0\n\n"
				# puts match_file[0]
				# puts "---FILE1\n\n"
				# puts match_file[1]

				callback.call(" - extracting data for #{match}") unless callback.nil?

				data[0] = read_data match_file[0]
				data[1] = read_data match_file[1]

				callback.call(" - adding #{match} result") unless callback.nil?
				result << [
					{
						filename: 	data[0][:filename],
						html:  		strip_a("<PRE>#{data[0][:html]}</PRE>"),
						pct:  		Integer(top[:pct0]),
						url: 		match_url,
						part_url: 	"#{uri}/match#{id}-0.html"
					},
					{
						filename: 	data[1][:filename],
						html:  		strip_a("<PRE>#{data[1][:html]}</PRE>"),
						pct:  		Integer(top[:pct1]),
						url: 		match_url,
						part_url: 	"#{uri}/match#{id}-1.html"
					}
				]
			end
		rescue OpenURI::HTTPError
			#end when there are no more matches -- indicated by 404 when accessing matches-n-top.html
		end

		result
	end

	private

	def get_matches(uri, min_pct, callback)
		result = Array.new
		begin
			callback.call(" - Reading match data") unless callback.nil?
			page = open("#{uri}").read().encode('UTF-8', 'binary', invalid: :replace, undef: :replace, replace: '?')
			regex = /<TR><TD><A HREF=".*?match(?<match_id>\d+).html">.*\((?<pct0>\d+)%\)<\/A>\n.*?<TD><A.*?((?<pct0>\d+)%\))/i
			# puts "scanning page"
			page.scan(regex).each do | match |
				id, pct0, pct1 = match
				# puts "#{id}, #{pct0}, #{pct1}"
				if Integer(pct0) >= min_pct || Integer(pct1) >= min_pct
					result << id
				end
			end
			callback.call(" - Found #{result.count} match with at least #{min_pct}% similar") unless callback.nil?
		rescue
		end
		result
	end

	def strip_a(html)
		html.gsub(/<A.*?>.*?<\/A>/, '')
	end

	def read_data(match_file)
		regex = /<HR>\s+(?<filename>\S+)<p><PRE>\n(?<html>.*)<\/PRE>\n<\/PRE>\n<\/BODY>\n<\/HTML>/xm
		match_file.match(regex)
	end

	def read_pcts(top_file)
		regex = /<TH>(?<filename0>\S+)\s\((?<pct0>\d+)%\).*<TH>(?<filename1>\S+)\s\((?<pct1>\d+)%\)/xm
		top_file.match(regex)
	end

	def locate_files(files)
		files.each do |file|
			raise "Unable to locate base file(s) matching #{file}" if Dir.glob(file).length == 0
		end
	end

	def open_connection
		TCPSocket.new @server, @port
	end

	def send_header(moss_server)
		moss_server.write "moss #{@userid}\n"
		moss_server.write "directory #{@options[:directory_submission] ? 1 : 0 }\n"
		moss_server.write "X #{@options[:experimental_server] ? 1 : 0}\n"
		moss_server.write "maxmatches #{@options[:max_matches]}\n"
		moss_server.write "show #{@options[:show_num_matches]}\n"
		moss_server.write "language #{@options[:language]}\n"

		line = moss_server.gets
		if line.strip() != "yes"
			moss_server.write "end\n"
			raise "Invalid language option."
		end
	end
end
