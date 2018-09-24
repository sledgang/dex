# frozen_string_literal: true

module Dex
  class MessageBuilder
    attr_reader :buffer

    def self.build(&block)
      instance = new
      yield instance
      instance.buffer.string
    end

    def initialize
      @buffer = StringIO.new
    end

    def write(string)
      @buffer << string
      string
    end

    def newline
      write("\n")
    end

    def space
      write(" ")
    end

    def italics
      write("*")
      yield
      write("*")
    end

    def bold
      write("**")
      yield
      write("**")
    end

    def inline_code_block
      write("`")
      yield
      write("`")
    end

    def code_block(lang = "rb")
      write("\n```#{lang}\n")
      yield
      write("\n```\n")
    end
  end
end
