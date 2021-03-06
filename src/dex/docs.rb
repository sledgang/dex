# frozen_string_literal: true

require "yard"

# Classes that control the rendering of YARD content into Discord messages
module Dex
  module Docs
    extend self

    # Parses a path and returns the processed rendering object
    def lookup(path)
      case path
      when /[A-Z]\S+#\S+/i
        InstanceMethod.new(path)
      when /[A-Z]\S+\.\S+/i
        ClassMethod.new(path)
      else
        Object.new(path)
      end
    end

    # Exception to raise when we can't find a YARD object
    class LookupFail < RuntimeError
    end

    # A container for a reply back to discord
    Reply = Struct.new(:content, :embed)

    # Module for helpers for building embeds
    module Embed
      # For building links to RubyDoc
      RUBYDOC_URL = "http://www.rubydoc.info/github/meew0/discordrb/master"

      # For building links to Git Docs
      GITHUB_PAGES_URL = "https://meew0.github.io/discordrb/master"

      # Does this really need explaining?
      RUBY_TACO = "https://cdn.discordapp.com/emojis/315242245274075157.png"

      # Git Version of the library
      GIT_VERSION = Bundler.load.specs["discordrb"].first.git_version.strip

      # Base link for the library source
      GITHUB_URL = "https://github.com/meew0/discordrb"

      # Utility method that yields a template embed
      def new_embed
        definitions = files.map do |f|
          path = f[0].split("/")[8..-1].join("/")
          line = f[1]
          "[`#{path}#L#{line}`](#{GITHUB_URL}/tree/#{GIT_VERSION}/lib/#{path}#L#{line})"
        end.join("\n")

        Discordrb::Webhooks::Embed.new(
          color: 0xff0000,
          url: github_pages_url,
          title: "[View on Git Docs]",
          description: definitions,
          footer: {text: "discordrb v#{Discordrb::VERSION}@#{GIT_VERSION}", icon_url: RUBY_TACO},
        ).tap { |e| yield e if block_given? }
      end

      def embed
        new_embed
      end

      # Builds a link to Git Docs
      def github_pages_url
        link = object.path.gsub("::", "/")
        link.tr!("?", "%3F")

        "#{GITHUB_PAGES_URL}/#{link}#{link_suffix}"
      end

      # Builds a permalink to RubyDoc
      def permalink
        link = object.path.gsub("::", "%2F")
        link.tr!("?", "%3F")
        link.tr!("#", ":")

        "#{RUBYDOC_URL}/#{link}"
      end
    end

    # A generic YARD lookup mixin
    module Lookup
      include Embed

      # The source path to this docs object
      attr_reader :path

      # The cached docs object
      attr_reader :object

      def initialize(path)
        @path = path.start_with?("Discordrb::") ? path : "Discordrb::#{path}"
        @object = lookup

        if object.nil? && /(?<namespace>\S+)(?<separator>[.#])(?<name>\S+)/i =~ @path
          parent = YARD::Registry.at(namespace)
          @object = parent.meths.find { |method| method.name.to_s == name && method.sep == separator } if parent
        end

        raise LookupFail, "Docs for `#{path}` not found" unless object
      end

      # Load YARD into this thread's cache
      private def load
        YARD::Registry.load!("discordrb")
      end

      # Renders this lookup into a Discord-ready `Reply`
      # Classes should override this method to render content in a custom way
      def render
        content = MessageBuilder.build do |msg|
          return_tag = tags.find do |tag|
            tag.tag_name == "return"
          end

          attr_kind = if reader? && writer?
                        "attr_accessor"
                      elsif reader? && !writer?
                        "attr_reader"
                      elsif writer? && !reader?
                        "attr_writer"
                      end

          msg.bold do
            msg.write path
            if return_tag
              types_signature = return_tag.types.join(", ")
              msg.write(" \u{279c} (#{types_signature})")
            end
          end

          msg.space

          msg.inline_code_block do
            msg.write("[#{type}, #{visibility}")
            msg.write(", #{attr_kind}") if attr_kind
            msg.write(", alias: #{name}") if @alias
            msg.write("]")
          end

          msg.newline

          if docstring.empty?
            if return_tag
              msg.write(return_tag.text.capitalize)
            else
              msg.italics do
                msg.write("No documentation available..")
              end
            end
          else
            msg.write(docstring)
          end

          if signature
            msg.code_block do
              msg.write(signature)
            end
          end
        end

        Reply.new(content, embed)
      end

      # Pulls this object from YARD's cache
      def lookup
        load
        YARD::Registry.at(@path)
      end

      # Returns the docs object's docstring, but removes YARD's wrapping
      def docstring
        object.docstring.tr("\n", " ")
      end

      # Delegate missing methods onto the cached docs object
      def method_missing(call)
        object.send(call)
      end
    end

    # Describes rendering for objects and modules
    class Object
      include Lookup

      def reader?
        false
      end

      def writer?
        false
      end

      def link_suffix
        nil
      end
    end

    # Describes rendering for methods
    class Method
      include Lookup

      # The alias of the object if it exists
      attr_reader :alias

      def initialize(path)
        super(path)

        return unless object.is_alias?
        @alias = object
        @object = YARD::Registry.at("#{object.namespace.path}#{object.sep}#{object.namespace.aliases[object]}")
      end
    end

    # Describes rendering for instance methods
    class InstanceMethod < Method
      def link_suffix
        "-instance_method"
      end
    end

    # Describes rendering for class methods (not sure if needed)
    class ClassMethod < Method
      def link_suffix
        "-class_method"
      end
    end
  end
end
