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

# This is the last time the data was loaded
$last_loaded = 0

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
      key    = $2.to_s

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
  set :static_cache_control, [:public, :max_age => 3600]

  # Output STDOUT immediately, do not buffer (for logging sake)
  $stdout.sync = true

  # Global things
  $storage = Fog::Storage.new(:provider => :aws,
                              :aws_access_key_id => settings.aws_access_key_id,
                              :aws_secret_access_key => settings.aws_secret_access_key)
  $bucket  = $storage.directories.get(settings.aws_bucket)

  # Load initial data
  reload!
end

before do
  if Time.now.to_i - $last_loaded > (60 * 5)
    $last_loaded = Time.now.to_i

    Thread.new do
      logger.info "Reloading data..."
      reload!
    end
  end
end

helpers do
  def file_type(file)
    file.key.split(".").last
  end

  def file_url(file)
    return "http://files.vagrantup.com/#{file.key}"
  end
end

get '/' do
  @tags = []
  $tags.keys.each do |tag|
    @tags << tag if tag !~ /\.[a-zA-Z].+$/
  end

  @tags.sort!
  erb :index
end

get '/tags/:tag' do
  return erb:'404' if !$tags.has_key?(params[:tag])
  return erb:'404' if !$packages.has_key?($tags[params[:tag]])

  @tag   = params[:tag]
  @files = $packages[$tags[params[:tag]]]
  erb :files
end
