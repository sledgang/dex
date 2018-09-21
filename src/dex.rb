# frozen_string_literal: true

require "pry"
require_relative "dex/bot"
require_relative "dex/message_builder"
require_relative "dex/docs"
require_relative "dex/lenny"

# Master module
module Dex
  Discordrb::LOGGER.info "Loading docs.."
  YARD.parse("vendor/bundle/ruby/#{RUBY_VERSION[0..-2]}0/bundler/gems/discordrb-*/**/*.rb")
  YARD::Registry.save(false, "discordrb")

  B1NZY = Discordrb::Commands::SimpleRateLimiter.new
  B1NZY.bucket(:docs, limit: 3, time_span: 30)
  B1NZY.bucket(:info, limit: 1, time_span: 60)

  # Maximum method source length to post to chat
  MAX_LINES = 20

  # "Lightweight" Discord message
  Message = Struct.new(:channel_id, :author_id, :content) do
    def self.from_json(string)
      parsed = JSON.parse(string)
      new(
        parsed["channel_id"].to_i,
        parsed["author"]["id"].to_i,
        parsed["content"]
      )
    end
  end

  module_function

  # Dispatch a command message to other command methods
  def dispatch(message)
    case message.content
    when /^\?doc|dex\.doc\s/
      unless B1NZY.rate_limited?(:docs, message.channel_id)
        Discordrb::LOGGER.info("Handling docs request: #{message.inspect}")
        handle_doc_request(message)
      else
        Discordrb::LOGGER.warn("Docs rate limit exceded in #{message.channel_id}")
      end
    when /^(\?|dex\.)s(au|our)ce/
      unless B1NZY.rate_limited?(:docs, message.channel_id)
        Discordrb::LOGGER.info("Handling source request: #{message.inspect}")
        handle_source_request(message)
      else
        Discordrb::LOGGER.warn("Docs rate limit exceded in #{message.channel_id}")
      end
    when /^dex.info/
      unless B1NZY.rate_limited?(:info, message.channel_id)
        Discordrb::LOGGER.info("Handling info request: #{message.inspect}")
        handle_info_request(message)
      else
        Discordrb::LOGGER.warn("Info rate limit exceded in #{message.channel_id}")
      end
    end
  end

  # Recall docs into chat
  def handle_doc_request(message)
    path = message.content.split(" ")[1]
    return Bot.send_message(message.channel_id, Lenny.get) unless path

    begin
      object = Docs.lookup(path)

      return Bot.send_message(message.channel_id, Lenny.get) unless object
      Discordrb::LOGGER.info("Found: #{object.class} @ #{path}")

      reply = object.render
      Bot.send_message(message.channel_id, reply.content, reply.embed.to_hash)
    rescue Docs::LookupFail => ex
      Discordrb::LOGGER.info("Error: #{ex.message}")
      Bot.send_message(message.channel_id, "#{ex.message} #{Lenny.get}", nil, 10)
    end
  end

  # Print method source
  def handle_source_request(message)
    path = message.content.split(" ")[1]
    return Bot.send_message(message.channel_id, Lenny.get) unless path

    begin
      object = Docs.lookup(path)

      return Bot.send_message(message.channel_id, Lenny.get) unless object
      Discordrb::LOGGER.info("Found: #{object.class} @ #{path}")

      return Bot.send_message(message.channel_id, "Can only print source of methods.. #{Lenny.get}") unless object.is_a?(Docs::InstanceMethod)

      source = object.source
      lines = source.count("\n")
      return Bot.send_message(message.channel_id, "Method source too long #{Lenny.get} `(#{lines} / #{MAX_LINES})`", object.embed) if lines > MAX_LINES

      Bot.send_message(message.channel_id, "```rb\n#{source}\n```", object.embed.to_hash)
    rescue Docs::LookupFail => ex
      Discordrb::LOGGER.info("Error: #{ex.message}")
      Bot.send_message(message.channel_id, "#{ex.message} #{Lenny.get}", nil, 10)
    end
  end

  # General bot info
  def handle_info_request(message)
    embed = Discordrb::Webhooks::Embed.new.tap do |e|
      e.description = <<~DOC
        **Commit:**
        ```
        #{`git log -n 1 --oneline`}
        ```
        [Source code](https://github.com/y32/dex)
        [discordrb](#{Docs::Embed::GITHUB_URL})
      DOC

      e.url = "https://github.com/z64"
      e.title = "Created by z64#1337 and friends"
      e.thumbnail = {url: Docs::Embed::RUBY_TACO}
    end

    Bot.send_message(
      message.channel_id,
      "**Usage:** `?doc Class`, `?doc Class#method`, `?source Class#method`",
      embed.to_hash
    )
  end

  # IPC loop
  UNIXSocket.open(ENV["DEX_BROKER_SOCKET"]) do |socket|
    Discordrb::LOGGER.info("Connected to IPC")
    loop do
      begin
        size = socket.recv(4).unpack("l").first
        raw_message = socket.recv(size)
        message = Message.from_json(raw_message)
        dispatch(message)
      rescue => ex
        Discordrb::LOGGER.error("Dispatch exception: #{ex.message}\n#{ex.backtrace.join("\n")}")
      end
    end
  end
end
