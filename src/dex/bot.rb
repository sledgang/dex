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

    # Sends a message, optionally deleting it after a delay
    def send_message(channel_id, content, embed = nil, delete_after = nil)
      response = JSON.parse(
        Discordrb::API::Channel.create_message(
          config.token,
          channel_id,
          content,
          false,
          embed
        )
      )

      if delete_after
        Thread.new do
          sleep delete_after
          delete_message(channel_id, response["id"])
        end
      end

      response
    end

    # Deletes a message
    def delete_message(channel_id, message_id)
      Discordrb::API::Channel.delete_message(
        config.token,
        channel_id,
        message_id
      )
    end
  end
end
