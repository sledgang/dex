require 'yard'

module Docs
  # Embed a class object
  def embed_class(object)
    object.meths.map { |m| "`#{m.path}`" }.join(', ')

    fresh_embed(object) do |embed|
      embed.title = 'View on RubyDoc'
      embed.url = permalink(object.path)

      # TODO: Paginate?
      # embed.description = object.meths.take(10).map { |m| "[#{m.name}](#{permalink(m.path)})" }.join(', ')
    end
  end

  # Embed a method object
  def embed_method(object)
    fresh_embed(object) do |embed|
      embed.add_field(
        name: 'Parameters',
        value: object.tags.map do |tag|
          "\u{25ab}**[#{tag.tag_name}]** `#{tag.name}` [#{tag.types&.join(', ')}]\n#{tag.text}"
        end.join("\n")
      )
    end
  end

  private

  def fresh_embed(object)
    Discordrb::Webhooks::Embed.new(
      color: 0xff0000,
      title: 'View on RubyDoc',
      url: permalink(object.path)
    ).tap { |e| yield e }
  end

  RUBYDOC = 'http://www.rubydoc.info/github/meew0/discordrb'

  def permalink(path)
    path.gsub!('::', '%2F')
    path.gsub!('#', ':')

    "#{RUBYDOC}/#{path}"
  end
end
