require 'fog'
require 'sinatra'

# Local files
require "./tags"

# This is the hash that will store the list of packages directly
# by tag name or by SHA1 ref.
$packages = {}

# This stores all the valid tags and the package commit they point
# to.
$tags = {}

def reload!
  # Reload the tags from the GitHub repo
  tags = Tags.all(settings.github_repo)
  tags = tags.invert

  # This will represent the list of valid tags as well as the full
  # list of packages.
  result_packages = {}
  result_tags = {}

  # Reload the files listing for the bucket
  $bucket.reload

  # Go through the files and find which releases have packages
  $bucket.files.all(:prefix => "packages").each do |file|
    if file.key =~ /^packages\/([a-z0-9]+)\/(.+?)$/
      commit = $1.to_s
      file   = $2.to_s

      # First check if we have a valid tag and if so, record it
      if tags.has_key?(commit)
        result_tags[tags[commit]] = commit
      end

      # Record the package
      result_packages[commit] ||= []
      result_packages[commit] << file
    end
  end

  # Flip the bits
  $packages = result_packages
  $tags     = result_tags
end

configure do
  # App-specific configuration options
  set :aws_access_key_id, ENV["AWS_ACCESS_KEY_ID"]
  set :aws_secret_access_key, ENV["AWS_SECRET_ACCESS_KEY"]
  set :aws_bucket, ENV["AWS_BUCKET"]
  set :github_repo, ENV["GITHUB_REPO"]

  # Sinatra options
  enable :logging

  # Output STDOUT immediately, do not buffer (for logging sake)
  $stdout.sync = true

  # Global things
  $storage = Fog::Storage.new(:provider => :aws,
                              :aws_access_key_id => settings.aws_access_key_id,
                              :aws_secret_access_key => settings.aws_secret_access_key)
  $bucket  = $storage.directories.get(settings.aws_bucket)

  # Create a thread that will refresh our data every so often
  Thread.new do
    while true
      # Load all the things
      puts "Reloading the S3 data..."
      reload!

      # Sleep for a long time
      sleep(60 * 5)
    end
  end
end

get '/' do
  erb :index
end
