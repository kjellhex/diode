# ![Diode](logo.svg)

# Diode

Diode lets you quickly build a fast, simple, pure-ruby application server.

## Installation

Add this line to your application's Gemfile:

``` ruby
gem 'diode'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install diode

## Usage

``` ruby
class Hello
  def serve(request)
    body = JSON.dump({ "message": "Hello World!" })
    Diode::Response.new(200, body)
  end
end

require 'diode/server'
routing = [
  [%r{^/}, "Hello"]
]
Diode::Server.new(3999, routing).start
# visit http://localhost:3999/
```

## Contributing

We welcome contributions to this project.

1.  Fork it.
2.  Create your feature branch (`git checkout -b my-new-feature`).
3.  Commit your changes (`git commit -am 'Add some feature'`).
4.  Push to the branch (`git push origin my-new-feature`).
5.  Create new Pull Request.

