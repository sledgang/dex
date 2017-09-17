require 'pry'
require_relative 'dex/bot'
require_relative 'dex/docs'
require_relative 'dex/lenny'

module Dex
  extend Bot
  extend Docs
  extend Lenny

  Discordrb::LOGGER.info 'Loading docs..'
  YARD.parse('vendor/bundle/ruby/*/bundler/gems/discordrb-*/**/*.rb')
  YARD::Registry.save(false, 'discordrb')

  # Recall docs into chat
  bot.message(start_with: 'dex.doc', in: config.channels) do |event|
    YARD::Registry.load!('discordrb')

    path = event.message.content[7..-1].strip
    object = YARD::Registry.at(
      path.start_with?('Discordrb::') ? path : "Discordrb::#{path}"
    )

    next event.respond(lenny) unless object

    embed = if path.include?('#')
              embed_method(object)
            else
              embed_class(object)
            end

    path = object.path.gsub('%2F', '::')

    content = <<~DOC
    **#{path}**
    #{object.docstring.gsub("\n", ' ')}
    DOC

    event.channel.send_embed(content, embed)
  end

  bot.run(:async)
  binding.pry if ARGV[0] == 'pry'
  bot.sync
end
