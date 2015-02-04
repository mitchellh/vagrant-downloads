gem 'rack-rewrite', '~> 1.5'
require 'rack/rewrite'
use Rack::Rewrite do
  r301 '/', 'https://www.vagrantup.com/downloads-archive.html'
end

class App
  def self.call(env)
    [200, {}, ""]
  end
end

run App
