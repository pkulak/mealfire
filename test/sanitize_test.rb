require File.expand_path('test_helper.rb', File.dirname(__FILE__))
require 'bacon'

Bacon.summary_on_exit

describe 'sanitizer' do
  it 'sanitizes strings' do
    s1 = '<p style="font-size:13px;position:absolute;left:10px;top:0;">Hi there!<script>hh</script></p>'
    s2 = '<img src="http://google.com"><a href="http://google.com"><b>Google</b></a>'
    
    MF::Sanitizer.sanitize(s1).should == '<p style="font-size:13px;">Hi there!</p>'
    MF::Sanitizer.sanitize(s2).should == s2
    MF::Sanitizer.sanitize('<body></body>').should == ''
    
    MF::Sanitizer.sanitize(%q{<a href="javascript:alert('Hi There!')">Click</a>})
      .should == %q{<a>Click</a>}
  end
  
  it 'sanitizes deeply nested strings' do
    s = '<div><blockquote><div><p><script>kk</script></p></div></blockquote></div>'
    MF::Sanitizer.sanitize(s).should == '<div><div><p></p></div></div>'
  end
end