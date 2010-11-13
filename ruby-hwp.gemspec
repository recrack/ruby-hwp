Kernel.load File.dirname(__FILE__) + '/lib/hwp/version.rb'

PKG_NAME = 'ruby-hwp'
PKG_VERSION = HWP::VERSION

Gem::Specification.new do |spec|
	spec.name = PKG_NAME
	spec.version = PKG_VERSION
	spec.summary = 'Ruby HWP library'
	spec.description = 'A library for easy read access to HWP documents for Ruby'

	spec.required_ruby_version = '>= 1.9.1'
	spec.requirements << 'ruby-ole 1.2.9 or higher'
	spec.requirements << 'builder 2.1.2 or higher'
	spec.add_dependency('ruby-ole', '>= 1.2.9')
	spec.add_dependency('builder', '>= 2.1.2')

	spec.files  = ['README', 'TODO', 'Rakefile', 'ruby-hwp.gemspec'] +
	spec.files += Dir.glob('lib/**/*.rb')
	spec.files += Dir.glob('bin/*')
	spec.executables = ['hwp2txt', 'hwp2html']

	spec.has_rdoc = false

	spec.author = 'Hodong Kim'
	spec.email = 'cogniti@gmail.com'
	spec.homepage = 'http://github.com/cogniti/ruby-hwp'
end
