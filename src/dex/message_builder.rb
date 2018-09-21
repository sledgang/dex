# frozen_string_literal: true

module Dex
  class MessageBuilder
    attr_reader :buffer

    def self.build(&block)
      instance = new
      instance.instance_eval(&block)
      instance.buffer.string
    end

    def initialize
      @buffer = StringIO.new
    end

    def write(str)
      @buffer << str
    end

    def newline
      @buffer << "\n"
    end

    def italics
      @buffer << "*"
      yield
      @buffer << "*"
    end

    def bold
      @buffer << "**"
      yield
      @buffer << "**"
    end

    def inline_code_block(inline = true, lang = "rb")
      @buffer << "`"
      yield
      @buffer << "`"
    end

    def code_block(lang = "rb")
      backticks = "```"
      @buffer << newline << backticks << lang << newline
      yield
      @buffer << newline << backticks << newline
    end
  end
end
