require "spec_helper"

describe MossRuby do

  it "has a version number" do
    expect(MossRuby::VERSION).not_to be nil
  end

	describe "#new" do
    before :each do
        @moss = MossRuby.new "myid"
    end
    
    it "takes the id parameter and returns a MossRuby object" do
      	expect(@moss).to be_an_instance_of MossRuby
  	end

  	it "creates an object with default server path" do
  		expect(@moss.server).to eql "moss.stanford.edu"
  	end

  	it "creates an object with default port" do
  		expect(@moss.port).to eql 7690
  	end

  	it "creates an object with the passed in userid" do
  		expect(@moss.userid).to eql "myid"
  	end

  	it "creates an object with default options" do
  		expect(@moss.options.has_key? :max_matches).to eql true
  		expect(@moss.options.has_key? :directory_submission).to eql true
  		expect(@moss.options.has_key? :show_num_matches).to eql true
  		expect(@moss.options.has_key? :experimental_server).to eql true
  		expect(@moss.options.has_key? :comment).to eql true
  		expect(@moss.options.has_key? :language).to eql true
  		expect(@moss.options.length).to eql 6
  	end
end

describe "#check" do

	before :each do
  		@server = double('server')
  		allow(TCPSocket).to receive(:new).and_return(@server)
	end

	def file_hash
		result = MossRuby.empty_file_hash
		test_dir = File.join(File.dirname(__FILE__), 'test_files')
		MossRuby.add_file(result, "#{test_dir}/*.c")
		result
	end

	it "opens a TCP connection to the server and asks to confirm language and get results" do
		expect(@server).to receive(:write).at_least(:once)
		expect(@server).to receive(:gets) { "yes" }
		expect(@server).to receive(:gets) { "http://moss.stanford.edu/results/706783168\n" }
		expect(@server).to receive(:close)

		@moss.check file_hash
	end

	it "raises an exception if the language is not known" do
		expect(@server).to receive(:write).at_least(:once)
		expect(@server).to receive(:gets) { "no" }
		expect(@server).to receive(:close)

		expect { @moss.check file_hash }.to raise_error("Invalid language option.")
	end

	it "sends requests to the server using the default options" do
		expect(@server).to receive(:write).with("moss myid\n")
		expect(@server).to receive(:write).with("directory 0\n")
		expect(@server).to receive(:write).with("X 0\n")
		expect(@server).to receive(:write).with("maxmatches 10\n")
		expect(@server).to receive(:write).with("show 250\n")
		expect(@server).to receive(:gets) { "yes" }
		expect(@server).to receive(:write).with("language c\n")
		expect(@server).to receive(:write).with("query 0 \n")
		expect(@server).to receive(:gets) { "http://moss.stanford.edu/results/706783168\n" }
		expect(@server).to receive(:write).with("end\n")
		expect(@server).to receive(:close)

		allow(@server).to receive(:write)

		@moss.check file_hash
	end

	it "sends requests to the server using supplied options" do
		@moss.userid = "fred"
		@moss.options[:directory_submission] = true
		@moss.options[:experimental_server] = true
		@moss.options[:max_matches] = 100
		@moss.options[:show_num_matches] = 85
		@moss.options[:language] = "python"
		@moss.options[:comment] = "Hello World"

		expect(@server).to receive(:write).with("moss fred\n")
		expect(@server).to receive(:write).with("directory 1\n")
		expect(@server).to receive(:write).with("X 1\n")
		expect(@server).to receive(:write).with("maxmatches 100\n")
		expect(@server).to receive(:write).with("show 85\n")
		expect(@server).to receive(:gets) { "yes" }
		expect(@server).to receive(:write).with("language python\n")
		expect(@server).to receive(:write).with("query 0 Hello World\n")
		expect(@server).to receive(:gets) { "http://moss.stanford.edu/results/706783168\n" }
		expect(@server).to receive(:write).with("end\n")
		expect(@server).to receive(:close)

		allow(@server).to receive(:write)

		@moss.check file_hash
	end

	RSpec::Matchers.define :a_file_like do |filename, lang|
			match { |actual| /file [0-9]+ c [0-9]+ .*#{filename}\n/.match(actual) }
	end

	RSpec::Matchers.define :text_starting_with do |line|
			match { |actual| actual.start_with? line }
	end

	RSpec::Matchers.define :text_matching_pattern do |pattern|
		match { |actual| (actual =~ pattern) == 0 }
	end

	it "sends files it is provided" do
		expect(@server).to receive(:write).with("moss myid\n")
		expect(@server).to receive(:write).with("directory 0\n")
		expect(@server).to receive(:write).with("X 0\n")
		expect(@server).to receive(:write).with("maxmatches 10\n")
		expect(@server).to receive(:write).with("show 250\n")
		expect(@server).to receive(:gets) { "yes" }
		expect(@server).to receive(:write).with("language c\n")
		expect(@server).to receive(:write).with("query 0 \n")
		expect(@server).to receive(:gets) { "http://moss.stanford.edu/results/706783168\n" }

		expect(@server).to receive(:write).with(a_file_like("hello.c", "c"))
		expect(@server).to receive(:write).with(text_starting_with("#include <stdio.h>\n\nint main()")).at_least(:once)

		expect(@server).to receive(:write).with(a_file_like("hello2.c", "c"))
		allow(@server).to receive(:write).with(text_matching_pattern( /file\s+\d\s+c\s+\d+\s+.*\/moss-ruby\/spec\/test_files\/.*\.c\n/))

		expect(@server).to receive(:write).with("end\n")
		expect(@server).to receive(:close)

		@moss.check file_hash
	end
end

describe "#extract_results" do
	before :each do
  		@uri = "http://moss.stanford.edu/results/706783168"
  		response = {
      index: '<HTML>
<HEAD>
<TITLE>Moss Results</TITLE>
</HEAD>
<BODY>
Moss Results<p>
Wed Jul  6 21:31:01 PDT 2016
<p>
Options -l c -m 10
<HR>
[ <A HREF="http://moss.stanford.edu/general/format.html" TARGET="_top"> How to Read the Results</A> | <A HREF="http://moss.stanford.edu/general/tips.html" TARGET="_top"> Tips</A> | <A HREF="http://moss.stanford.edu/general/faq.html"> FAQ</A> | <A HREF="mailto:moss-request@cs.stanford.edu">Contact</A> | <A HREF="http://moss.stanford.edu/general/scripts.html">Submission Scripts</A> | <A HREF="http://moss.stanford.edu/general/credits.html" TARGET="_top"> Credits</A> ]
<HR>
<TABLE>
<TR><TH>File 1<TH>File 2<TH>Lines Matched
<TR><TD><A HREF="http://moss.stanford.edu/results/286379385/match0.html">test2.c (75%)</A>
  <TD><A HREF="http://moss.stanford.edu/results/286379385/match0.html">test3.c (75%)</A>
<TD ALIGN=right>3
</TABLE>
<HR>
Any errors encountered during this query are listed below.<p></BODY>
</HTML>',
			top: '<HTML>
<HEAD>
<TITLE>Top</TITLE>
</HEAD><BODY BGCOLOR=white><CENTER><TABLE BORDER="1" CELLSPACING="0" BGCOLOR="#d0d0d0"><TR><TH>../test/test2.c (75%)<TH><IMG SRC="http://moss.stanford.edu/bitmaps/tm_0_75.gif" BORDER="0" ALIGN=left><TH>../test/test3.c (85%)<TH><IMG SRC="http://moss.stanford.edu/bitmaps/tm_0_75.gif" BORDER="0" ALIGN=left><TH>
<TR><TD><A HREF="http://moss.stanford.edu/results/706783168/match0-0.html#0" NAME="0" TARGET="0">3-5</A>
<TD><A HREF="http://moss.stanford.edu/results/706783168/match0-0.html#0" NAME="0" TARGET="0"><IMG SRC="http://moss.stanford.edu/bitmaps/tm_0_75.gif" ALT="link" BORDER="0" ALIGN=left></A>
<TD><A HREF="http://moss.stanford.edu/results/706783168/match0-1.html#0" NAME="0" TARGET="1">3-5</A>
<TD><A HREF="http://moss.stanford.edu/results/706783168/match0-1.html#0" NAME="0" TARGET="1"><IMG SRC="http://moss.stanford.edu/bitmaps/tm_0_75.gif" ALT="link" BORDER="0" ALIGN=left></A>
</TABLE></CENTER></BODY></BODY></HTML>',
			m00: '<HTML>
<HEAD>
<TITLE>../test/test2.c</TITLE>
</HEAD>
<BODY BGCOLOR=white>
<HR>
../test/test2.c<p><PRE>
#include &lt;stdio.h&gt;

<A NAME="0"></A><FONT color = #FF0000><A HREF="match0-1.html#0" TARGET="1"><IMG SRC="http://moss.stanford.edu/bitmaps/tm_0_75.gif" ALT="other" BORDER="0" ALIGN=left></A>

int main()
{
printf("Hello Andrew");
</FONT>}</PRE>
</PRE>
</BODY>
</HTML>

',
			m01: '<HTML>
<HEAD>
<TITLE>../test/test3.c</TITLE>
</HEAD>
<BODY BGCOLOR=white>
<HR>
../test/test3.c<p><PRE>
#include &lt;stdio.h&gt;

<A NAME="0"></A><FONT color = #FF0000><A HREF="match0-0.html#0" TARGET="0"><IMG SRC="http://moss.stanford.edu/bitmaps/tm_0_75.gif" ALT="other" BORDER="0" ALIGN=left></A>

int main()
{
printf("Hello Andrew");
</FONT>}</PRE>
</PRE>
</BODY>
</HTML>

'
		}
    stub_request(:get, "http://moss.stanford.edu/results/706783168").to_return(:body => response[:index], :status => 200)

		stub_request(:get, "moss.stanford.edu/results/706783168/match0-top.html").to_return(:body => response[:top], :status => 200)
		stub_request(:get, "moss.stanford.edu/results/706783168/match0-0.html").to_return(:body => response[:m00], :status => 200)
		stub_request(:get, "moss.stanford.edu/results/706783168/match0-1.html").to_return(:body => response[:m01], :status => 200)

		stub_request(:get, "moss.stanford.edu/results/706783168/match1-top.html").to_return(:status => 404)
	end

	it "it makes the required calls to the server to get data on matches" do
		@moss.extract_results @uri
	end

	it "identifies filenames in its response" do
		result = @moss.extract_results @uri

		expect(result[0][0][:filename]).to eql "../test/test2.c"
		expect(result[0][1][:filename]).to eql "../test/test3.c"
	end

	it "identifies percentages in its response" do
		result = @moss.extract_results @uri

		expect(result[0][0][:pct]).to eql 75
		expect(result[0][1][:pct]).to eql 85
	end

	it "contains the HTML of the match in its response" do
		result = @moss.extract_results @uri

		expect(result[0][0][:html]).to eql '<PRE>#include &lt;stdio.h&gt;

<FONT color = #FF0000>

int main()
{
	printf("Hello Andrew");
</FONT>}</PRE>'
			expect(result[0][1][:html]).to eql '<PRE>#include &lt;stdio.h&gt;

<FONT color = #FF0000>

int main()
{
	printf("Hello Andrew");
</FONT>}</PRE>'
		end
	end
end
