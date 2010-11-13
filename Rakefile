require 'rake/gempackagetask'

spec = eval File.read('ruby-hwp.gemspec')

task :default => [:package]

Rake::GemPackageTask.new(spec) do |task|
	task.gem_spec = spec
	task.need_tar = true
	task.need_zip = false
	task.package_dir = 'build'
end
