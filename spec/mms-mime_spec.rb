require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

ROOT_DIR = File.expand_path(File.dirname(__FILE__) + '/..')

describe Mime::Mms::Parser, "when first created" do
  it "should not be nil" do
    p = Mime::Mms::Parser.new
    p.should_not be_nil
    p.message.class.should == Mime::Mms::Message
    p.message.subject.should be(nil)
  end
end

describe Mime::Mms::Parser, "when initialized from files" do
  %w(mms-1 mms-2 mms-3 mms-4 mms-5).each do |file|
    it "should parse file #{file}" do
      p = Mime::Mms::Parser.new :file => "#{ROOT_DIR}/spec/fixtures/#{file}.bin"
      m = p.parse
      m.parts.should_not be_nil
      m.parts.size.should > 0

      m.xml_parts.should_not be_nil
      m.xml_parts.size.should == 1

      m.image_parts.should_not be_nil
      m.image_parts.size.should > 0

      unless file == "mms-3"
        m.text_parts.should_not be_nil
        m.text_parts.size.should > 0
        m.text.should_not be_nil
      end
    end
  end

  it "should extract subject, shortcode and number from binary-encoded file" do
    p = Mime::Mms::Parser.new :file => "#{ROOT_DIR}/spec/fixtures/mms-1.bin"
    m = p.parse
    m.subject.should be_nil
    m.from.should == "14155556666"
    m.to.should == "43333"
  end
  
  it "should extract subject, shortcode and number from base64 encoded file" do
    p = Mime::Mms::Parser.new :file => "#{ROOT_DIR}/spec/fixtures/mms-5.bin"
    m = p.parse
    m.subject.should_not be_nil
    m.subject.should == "Test group of messages"
    m.text.should == "Test MM"
    m.from.should == "77777"
    m.to.should == "1"
    # File.open("image.jpg","w") { |f| f.write m.image_parts.first.body }
  end

end

