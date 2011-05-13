#
# This library supports parsing MM7-encoded MMS messages into a flat structure of
# image and text parts.
#
# Author: Konstantin Gredeskoul, 2010-2011
#
require "base64"

if RUBY_VERSION < "1.9"
  class File
    def self.read_binary(file)
      File.open(file,"rb") { |f| f.read }
    end
  end
else
  class File
    def self.read_binary(file)
      File.open(file,"rb:BINARY") { |f| f.read }
    end
  end
end

module Mime
  module Mms
    class Part < Struct.new(:header, :body, :content_type, :text, :image, :xml, :image_type) ; end

    class Message
      attr_accessor :parts
      attr_accessor :from
      attr_accessor :to
      attr_accessor :subject

      def initialize
        @parts = []
      end

      def add_part part
        parts << part
      end

      def image_parts
        @parts.select{|p| p.content_type =~ /image\/\w+/}
      end

      def text_parts
        @parts.select{|p| p.content_type =~ /text\/plain/}
      end

      def xml_parts
        @parts.select{|p| p.content_type =~ /text\/xml/}
      end

      def smil_parts
        @parts.select{|p| p.content_type =~ /smil/}
      end

      def text
        text_parts.inject(""){|all, p| "#{all}#{p.body} " }.chop
      end
      

    end

    class Parser
      attr :message

      def initialize params = nil
        @message = Message.new
        return if params.nil?
        @bytes = if params[:file]
          File.read_binary(params[:file])
        elsif params[:bytes]
          params[:bytes]
        else
          raise ArgumentError.new "please pass :bytes or :file as input"
        end
      end

      
      def parse
        parse_bytes(@bytes)
      end

      private

      def parse_bytes(bytes)
        content_blocks = bytes.split(/------=.*\n?/)
        content_blocks.each do |cb|
          header, body = cb.split(/\r\n\r\n/)
          # skip blank.. could be nested mime parts
          next if body.nil?
          part = Part.new(header, body)
          if header =~ /Content-Type: (.*)$/
            part.content_type = $1.chop
          end
          if part.content_type =~ /text\/xml/
            part.xml = true
            extract_details(part.body)
          end

          if header =~ /Content-Transfer-Encoding: binary/
            # not much to do, it's already binary
          elsif header =~ /Content-Transfer-Encoding: base64/
            part.body = Base64.decode64(part.body)
          end
        
          if part.content_type =~ /image\/(\w+)/
            part.image_type = $1
            part.image = true 
          elsif part.content_type =~ /text\/plain/
            part.body.chop!
            part.text = true
          end
          message.add_part part
        end
        message
      end

      def extract_details(input)
        if input =~/<\w+:Number>\+?(\d+)<\/\w+:Number>\s*<\/\w+:Sender\w*>/
          message.from = $1
        end
        if input =~/<\w+:Number[^>]*>\+?(\d+)<\/\w+:Number>\s*<\/\w+:To>/
          message.to = $1
        end
        if input =~/<\w+:Subject>(.*)<\/\w+:Subject>/
          message.subject = $1
        end
      end
    end
  end
end
