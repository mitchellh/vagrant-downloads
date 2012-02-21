# Vagrant Downloads Site

This is the source code for the Vagrant downloads site, which
is up at [downloads.vagrantup.com](http://downloads.vagrantup.com).

The purpose of the download site is to provide links to installers
and packages created for Vagrant. I wanted to make this as automated
as possible. Therefore, the way it works is as follows:

1. The Vagrant [installer generators](https://github.com/mitchellh/vagrant-installers)
   automatically upload the finished installer to S3 under the name
   `packages/COMMIT_SHA/FILENAME`.
1. The downloads app loads all the tags for Vagrant from the GitHub API
   along with all the files in the S3 bucket starting with "packages/."
1. Only the packages for commits that are a tag in the GitHub repo are
   listed.

## Running the Site Locally

First, grab the dependencies using [Bundler](http://gembundler.com):

    bundle

Then, run the site:

    bundle exec rackup

Note that the site requires some configuration in the form of environmental
variables. The environmental variables that the app expects are:

* `AWS_ACCESS_KEY_ID` - AWS access key that has file list permissions to an
  S3 bucket.
* `AWS_SECRET_ACCESS_KEY` - The secret access key that goes with the above
  access key.
* `AWS_BUCKET` - The AWS bucket where the packages are being stored.
* `GITHUB_REPO` - A GitHub repo in the form of `username/repo` that has the
  tags that correspond to the commit SHA for the packages.
