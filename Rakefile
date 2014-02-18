require 'rubygems'
require 'bundler'
require 'bundler/gem_tasks'
require 'version_bumper'

begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit e.status_code
end

# Get your spec rake tasks working in RSpec 2.0

require 'rspec/core/rake_task'

desc 'Default: run specs.'
task :default => :spec

desc "Run specs"
RSpec::Core::RakeTask.new do |t|
  # Put spec opts in a file named .rspec in root
end

require 'yard'
YARD::Rake::YardocTask.new do |t|
  t.options = ["--readme", "README.rdoc", '--protected']
end

desc "Run console; defaults to IRB='pry'"
task :console, :IRB do |t, args|
  irb = args[:IRB].nil?? 'pry' : args[:IRB]
  sh irb, "-r", "#{File.dirname(__FILE__)}/config/boot.rb"
end

desc "Execute integration tests"
task :integration, :jetty_home, :jetty_port, :java_opts do |t, args| 

  require 'jettywrapper'
  jetty_params = {
    :jetty_home => args.jetty_home,
    :java_opts => [args.java_opts], 
    :jetty_port => args.jetty_port, 
    :quiet => true,
    :startup_wait => 20
  }

  error = Jettywrapper.wrap(jetty_params) do
    Rake::Task['spec'].invoke
  end
  raise "test failures: #{error}" if error
end
