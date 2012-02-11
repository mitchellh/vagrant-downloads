require 'fog'
require 'sinatra'

# Local files
require "./tags"

# This is the hash that will store the list of packages directly
# by tag name or by SHA1 ref.
$packages = {}

configure do
  # App-specific configuration options
  set :aws_access_key_id, ENV["AWS_ACCESS_KEY_ID"]
  set :aws_secret_access_key, ENV["AWS_SECRET_ACCESS_KEY"]
  set :aws_bucket, ENV["AWS_BUCKET"]

  # Sinatra options
  enable :logging

  # Global things
  $tags    = Tags.all("mitchellh/vagrant")
  $storage = Fog::Storage.new(:provider => :aws,
                              :aws_access_key_id => settings.aws_access_key_id,
                              :aws_secret_access_key => settings.aws_secret_access_key)
  $bucket  = $storage.directories.get(settings.aws_bucket)
end

get '/' do
  $tags.keys.join("<br />")
end
