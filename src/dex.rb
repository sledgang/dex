require 'pry'
require_relative 'dex/bot'
require_relative 'dex/docs'
require_relative 'dex/lenny'

module Dex
  extend Bot
  extend Docs
  extend Lenny

  Discordrb::LOGGER.info 'Loading docs..'
  YARD.parse("vendor/bundle/ruby/#{RUBY_VERSION[0..-2]}0/bundler/gems/discordrb-*/**/*.rb")
  YARD::Registry.save(false, 'discordrb')

  B1NZY = Discordrb::Commands::SimpleRateLimiter.new
  B1NZY.bucket(:docs, limit: 3, time_span: 30)
  B1NZY.bucket(:info, limit: 1, time_span: 60)

  # Recall docs into chat
  bot.message(start_with: /\?doc|dex\.doc\s/, in: config.channels) do |event|
    next if B1NZY.rate_limited?(:docs, event.channel.id)

    path = event.message.content.split(' ')[1]
    Discordrb::LOGGER.info("[#{event.channel.name} | #{event.user.distinct}] Lookup: #{path}")

    next event.respond(lenny) if path.empty?

    begin
      object = lookup(path)

      next event.respond(lenny) unless object
      Discordrb::LOGGER.info("Found: #{object.class} @ #{path}")

      reply = object.render
      event.channel.send_embed(reply.content, reply.embed)
    rescue Docs::LookupFail => ex
      Discordrb::LOGGER.info("Error: #{ex.message}")
      event.send_temporary_message("#{ex.message} #{lenny}", 10)
    end
  end

  bot.message(content: 'dex.info') do |event|
    next if B1NZY.rate_limited?(:info, event.channel.id)

    event.channel.send_embed("**Usage:** `?doc Class`, `?doc Class#method`") do |embed|
      embed.description = <<~DOC
      [Source code](https://github.com/y32/dex)
      [discordrb](https://github.com/meew0/discordrb)
      DOC

      owner = bot.user(config.owner)
      embed.url = 'https://github.com/z64'
      embed.author = { name: owner.distinct, icon_url: owner.avatar_url }
      embed.thumbnail = { url: Docs::Embed::RUBY_TACO }
    end
  end

  bot.run(:async)
  binding.pry if ARGV[0] == 'pry'
  bot.sync
end
