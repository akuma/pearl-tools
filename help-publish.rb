#!/usr/bin/env ruby -w
# -*- coding: utf-8 -*-
# A ruby script for publishing help html pages to deployment repos.

require 'optparse'


VERSION  = %w(0 0 1)

# App publish dir
APP_PUBLISH_DIR = '/opt/scm/app-publish'
#APP_PUBLISH_DIR = '/Users/akuma/Programs/misc/app-test/git-publish'

# Program name
EXECUTOR_NAME = File.basename($PROGRAM_NAME)


options = {}
option_parser = OptionParser.new do |opts|
  opts.banner = "Publish help pages to deployment repos.
Usage: #{EXECUTOR_NAME} [options] app_name"

  opts.separator ''
  opts.separator 'Common options:'

  opts.on('-b',
          '--branch branch_name',
          'The branch name which to publish, default is master') do |branch_name|
    options[:branch_name] = branch_name
  end

  opts.on_tail('-h', '--help', 'Show this message') do
    puts opts
    exit 0
  end

  opts.on_tail('-v', '--version', 'Show version') do
    puts "#{EXECUTOR_NAME} #{VERSION.join('.')}"
    exit 0
  end
end

# Publish help pages to git repos.
def publish(app_name, branch_name)
  branch_name = branch_name || 'master'

  app_deploy_repos0 = "#{app_name}-deploy-#{branch_name}"
  app_deploy_dir = File.join(APP_PUBLISH_DIR, "#{app_deploy_repos0}")
  unless Dir.exist?(app_deploy_dir)
    app_deploy_repos1 = "#{app_name}-deploy"
    app_deploy_dir = File.join(APP_PUBLISH_DIR, "#{app_deploy_repos1}")
    unless Dir.exist?(app_deploy_dir)
      puts "  Ignore package #{pkg_name}: has no repos '#{app_deploy_repos0}' or '#{app_deploy_repos1}'"
      return
    end
  end

  working_dir = Dir.pwd
  puts "  Changing dir #{working_dir} -> #{app_deploy_dir}..."
  Dir.chdir(app_deploy_dir)

  # Checkout git branch
  `git checkout #{branch_name}`

  # Update package files of git repos
  puts "  Copying #{working_dir}/* -> #{app_deploy_dir}..."
  `cp -rp #{working_dir}/* .`

  # Delete files which are not used for deployment
  svn_dirs = File.join('**', '.svn')
  Dir.glob(svn_dirs).each { |x| Dir.rmdir(x) }

  # Git commit and push
  `git add .`
  `git commit -m 'Deployment publish commit.'`
  `git push origin #{branch_name}`

  # Go back to working dir
  Dir.chdir(working_dir)
end

begin
  option_parser.parse!
  #puts "options: #{options}"
  #puts "argv: #{ARGV}"

  if ARGV.empty?
    puts 'Error: you must supply a app_name'
    puts
    puts option_parser.help
  else
    app_name = ARGV[0]
    branch_name = options[:branch_name]
    publish(app_name, branch_name)
  end
rescue OptionParser::InvalidOption, OptionParser::MissingArgument => e
  puts "Error: #{e}"
  puts
  puts option_parser.help
end
