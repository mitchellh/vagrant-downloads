gem 'rack-rewrite', '~> 1.5'
require 'rack/rewrite'
use Rack::Rewrite do
  r301 '/', 'https://www.vagrantup.com/downloads-archive.html'
end
