# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'ibm/bluemix/service_discovery/version'

Gem::Specification.new do |spec|
  spec.name          = "ibm-bluemix-service_discovery"
  spec.version       = IBM::Bluemix::ServiceDiscovery::VERSION
  spec.authors       = ["Christopher Young"]
  spec.email         = ["krsyoung@gmail.com"]

  spec.summary       = %q{Library for using the IBM Bluemix Service Discovery service.}
  spec.description   = %q{Library to support microservices interacting with the IBM Bluemix Service Discovery service.  Use this library in your Rails or Sinatra based microservices to easily register and discover services in your Bluemix account.}
  spec.homepage      = "https://github.com/krsyoung/ibm-bluemix-service_discovery"
  spec.license       = "MIT"

  # # Prevent pushing this gem to RubyGems.org by setting 'allowed_push_host', or
  # # delete this section to allow pushing this gem to any host.
  # if spec.respond_to?(:metadata)
  #   spec.metadata['allowed_push_host'] = "TODO: Set to 'http://mygemserver.com'"
  # else
  #   raise "RubyGems 2.0 or newer is required to protect against public gem pushes."
  # end

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  s.required_ruby_version = '>= 1.9.3'

  spec.add_dependency "unirest", "~> 1.1"

  spec.add_development_dependency "bundler", "~> 1.11"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "byebug"
end
