# Blitzy

Implementation of the Blitzy distributed load-testing application described in Ch. 8+9 of [The Little Elixir and OTP Guidebook](https://www.manning.com/books/the-little-elixir-and-otp-guidebook). There are a few small deltas from the upstream implementation necessitated by movement in the Elixir language and ecosystem since publication.

## Installation

I'd advise against using this as a dependency anywhere, to be honest. If you'd 
like to take this for a spin (unlike upstream, this will run with Elixir 1.5),
pull, `mix deps.get`, and `mix escript.compile` to build the CLI app.

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
to the tiny degree to which this repo is tested.

