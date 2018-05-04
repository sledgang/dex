require 'yard'

# Classes that control the rendering of YARD content into Discord messages
module Docs
  # Parses a path and returns the processed rendering object
  # TODO: probably regex
  def lookup(path)
    return InstanceMethod.new(path) if path.include?('#')
    Object.new(path)
  end

  # Exception to raise when we can't find a YARD object
  class LookupFail < Exception
  end

  # A container for a reply back to discord
  Reply = Struct.new(:content, :embed)

  # Module for helpers for building embeds
  module Embed
    # For building permalinks
    RUBYDOC = 'http://www.rubydoc.info/github/meew0/discordrb/master'

    # Does this really need explaining?
    RUBY_TACO = 'https://cdn.discordapp.com/emojis/315242245274075157.png'

    # Git Version of the library
    GIT_VERSION = Bundler.load.specs['discordrb'].first.git_version.strip

    # Base link for the library source
    GITHUB_URL = 'https://github.com/meew0/discordrb'

    # Utility method that yields a template embed
    def new_embed
      definitions = files.map do |f|
        path, line = f[0].split('/')[8..-1].join('/'), f[1]
        "[`#{path}#L#{line}`](#{GITHUB_URL}/tree/#{GIT_VERSION}/lib/#{path}#L#{line})"
      end.join("\n")

      Discordrb::Webhooks::Embed.new(
        color: 0xff0000,
        url: permalink,
        title: '[View on RubyDoc]',
        description: definitions,
        footer: { text: "discordrb v#{Discordrb::VERSION}@#{GIT_VERSION}", icon_url: RUBY_TACO }
      ).tap { |e| yield e if block_given? }
    end

    def embed
      new_embed
    end

    # Builds a permalink to RubyDoc
    def permalink
      path.gsub!('::', '%2F')
      path.gsub!('?', '%3F')
      path.gsub!('#', ':')

      "#{RUBYDOC}/#{path}"
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
      @path = path.start_with?('Discordrb::') ? path : "Discordrb::#{path}"
      @object = lookup

      raise LookupFail, "Docs for `#{path}` not found" unless @object
    end

    # Load YARD into this thread's cache
    private def load
      YARD::Registry.load!('discordrb')
    end

    # Renders this lookup into a Discord-ready `Reply`
    # Classes should override this method to render content in a custom way
    def render
      # TODO: Less spaghetti handling of this. I can't seem to pull the docstrings
      # from attr_* and the likes...
      docs = if docstring.empty?
               if reader? && writer?
                 'attr_accessor'
               elsif reader? && !writer?
                 'attr_reader'
               elsif writer? && !reader?
                 'attr_writer'
               end
             else
               docstring
             end
      content = <<~DOC
      **#{path}** `[#{type}, #{visibility}#{docstring.empty? ? ", #{docs}" : nil}]`
      #{docstring.empty? ? 'No documentation available.' : docstring}
      DOC

      if sig = signature
        content << "```rb\n#{sig}\n```"
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
      object.docstring.gsub("\n", ' ')
    end

    # Delegate missing methods onto the cached docs object
    def method_missing(call)
      object.send(call)
    end
  end

  # Describes rendering for objects and modules
  class Object
    include Lookup
  end

  # Describes rendering for instance methods
  class InstanceMethod
    include Lookup
  end

  # Describes rendering for class methods (not sure if needed)
  class ClassMethod
    include Lookup
  end
end
