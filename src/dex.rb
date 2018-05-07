# frozen_string_literal: true

require "pry"
require_relative "dex/bot"
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

  # Recall docs into chat
  Bot.bot.message(start_with: /\?doc|dex\.doc\s/, in: Bot.config.channels) do |event|
    next if B1NZY.rate_limited?(:docs, event.channel.id)

    path = event.message.content.split(" ")[1]
    Discordrb::LOGGER.info("[#{event.channel.name} | #{event.user.distinct}] Lookup: #{path}")

    next event.respond(Lenny.get) unless path

    begin
      object = Docs.lookup(path)

      next event.respond(Lenny.get) unless object
      Discordrb::LOGGER.info("Found: #{object.class} @ #{path}")

      reply = object.render
      event.channel.send_embed(reply.content, reply.embed)
    rescue Docs::LookupFail => ex
      Discordrb::LOGGER.info("Error: #{ex.message}")
      event.send_temporary_message("#{ex.message} #{Lenny.get}", 10)
    end
  end

  # Print method source
  Bot.bot.message(start_with: /(\?|dex\.)s(au|our)ce/, in: Bot.config.channels) do |event|
    next if B1NZY.rate_limited?(:docs, event.channel.id)

    path = event.message.content.split(" ")[1]
    Discordrb::LOGGER.info("[#{event.channel.name} | #{event.user.distinct}] Source Lookup: #{path}")

    next event.respond(Lenny.get) unless path

    begin
      object = Docs.lookup(path)

      next event.respond(Lenny.get) unless object
      Discordrb::LOGGER.info("Found: #{object.class} @ #{path}")

      next event.respond("Can only print source of methods.. #{Lenny.get}") unless object.is_a?(Docs::InstanceMethod)

      source = object.source

      lines = source.count("\n")
      next event.channel.send_embed("Method source too long #{Lenny.get} `(#{lines} / #{MAX_LINES})`", object.embed) if lines > MAX_LINES

      event.channel.send_embed("```rb\n#{source}\n```", object.embed)
    rescue Docs::LookupFail => ex
      Discordrb::LOGGER.info("Error: #{ex.message}")
      event.send_temporary_message("#{ex.message} #{Lenny.get}", 10)
    end
  end

  # General bot info
  Bot.bot.message(content: "dex.info") do |event|
    next if B1NZY.rate_limited?(:info, event.channel.id)

    event.channel.send_embed("**Usage:** `?doc Class`, `?doc Class#method`, `?source Class#method`") do |embed|
      embed.description = <<~DOC
        **Commit:**
        ```
        #{`git log -n 1 --oneline`}
        ```
        [Source code](https://github.com/y32/dex)
        [discordrb](#{Docs::Embed::GITHUB_URL})
      DOC

      owner = event.bot.user(Bot.config.owner)
      embed.url = "https://github.com/z64"
      embed.author = {name: owner.distinct, icon_url: owner.avatar_url}
      embed.thumbnail = {url: Docs::Embed::RUBY_TACO}
    end
  end

  at_exit { Bot.bot.stop }

  Bot.bot.run(:async)
  binding.pry if ARGV[0] == "pry"
  Bot.bot.sync
end
