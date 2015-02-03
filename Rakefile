require 'rspec/core/rake_task'
require 'rubocop/rake_task'

Rubocop::RakeTask.new

RSpec::Core::RakeTask.new(:spec) do |r|
  r.pattern = FileList['**/**/*_spec.rb']
end

desc 'Make all plugins executable'
task :make_plugins_executable do
  `chmod -R +x **/*.rb`
end

task default: [:spec, :make_plugins_executable, :rubocop]

