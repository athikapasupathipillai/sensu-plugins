require 'date'
Gem::Specification.new do |gem|
  gem.name                  = 'sensu-oasis-plugins'
  gem.authors               = ['Oasiswork and contributors']
  gem.email                 = '<dev@oasiswork.fr>'
  gem.homepage              = 'https://github.com/oasis/sensu-plugins'
  gem.license               = 'MIT'
  gem.summary               = ' Oasiswork Sensu plugins '
  gem.description           = ' Oasiswork Sensu plugins '
  gem.version               = '0.0.0'
  gem.date                  = Date.today.to_s
  gem.platform              = Gem::Platform::RUBY

  gem.files                 = Dir['Rakefile', '**/*', 'README*', 'LICENSE*']

  gem.add_dependency 'sensu-plugin', '~> 1.1.0'

  gem.add_development_dependency 'bundler',           '~> 1.3'
  gem.add_development_dependency 'rubocop',           '~> 0.17.0'
  gem.add_development_dependency 'rake'
  gem.add_development_dependency 'rspec'
  gem.add_development_dependency 'rspec-mocks'
end

