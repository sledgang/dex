# **dex**

A [Discord](https://discord.com) bot for [discordrb](https://github.com/meew0/discordrb).

The bot works by using the [YARD](https://yardoc.org/) gem to parse discordrb's documentation, wrapping it in a handful of classes to render the documentation in a concise format within Discord.

## Running

Fill out a `config.yml`:
```yaml
---
token: token
channels:
- 298822592104759307
- 83281822225530880
- 345687437722386433
owner: 120571255635181568
```
And run:
```
$ rake install
$ rake
```

## Usage

### `dex.doc` (alias: `?doc`)

Looks up a class or method.

```
dex.doc Server#kick
?doc Server#ban
?doc API::Channel.resolve
```

### `dex.info`

Shows bot info.

## Contributors

- [z64](https://github.com/z64) Zac Nowicki - creator
