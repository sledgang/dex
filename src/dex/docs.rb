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

  # Module for helpers for building embeds
  # TODO: Also GitHub permalinks?
  module Embed
    # For building permalinks
    RUBYDOC = 'http://www.rubydoc.info/github/meew0/discordrb'

    # Utility method that yields a template embed
    def new_embed
      Discordrb::Webhooks::Embed.new(
        color: 0xff0000,
        title: 'View on RubyDoc',
        url: permalink
      ).tap { |e| yield e }
    end

    # Builds a permalink to RubyDoc
    def permalink
      path.gsub!('::', '%2F')
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
