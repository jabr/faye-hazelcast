$: << File.expand_path('../lib', __FILE__)

require 'faye/hazelcast/version'

Gem::Specification.new do |s|
  s.name              = 'faye-hazelcast'
  s.version           = Faye::Hazelcast::VERSION.dup
  s.summary           = 'Hazelcast backend engine for Faye'
  s.author            = 'Justin Bradford'
  s.email             = 'justin@etcland.com'
  s.homepage          = 'http://github.com/jabr/faye-hazelcast'
  s.licenses          = ['MIT', 'Apache-2.0']
  s.platform          = 'jruby'
  s.require_paths     = %w[lib]

  s.files = %w[CHANGELOG.md README.md] +
            Dir.glob('lib/**/*.rb') +
            Dir.glob('vendor/*.jar')

  s.add_dependency 'faye', '~> 1.0.1'
  s.add_runtime_dependency 'gson'
end
