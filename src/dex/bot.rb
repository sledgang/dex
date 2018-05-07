# frozen_string_literal: true

require "discordrb"
require "yaml"
require "ostruct"

# Discord Bot
module Dex
  module Bot
    extend self

    def config
      @config ||= OpenStruct.new YAML.load_file("config.yml")

      raise "invalid config" unless %i[
        token
        channels
        owner
      ].map { |e| @config.respond_to?(e) }.all?

      @config
    end

    def bot
      @bot ||= Discordrb::Bot.new(token: config.token)
    end
  end
end
