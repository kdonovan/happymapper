ProjectName = 'happymapper'
WebsitePath = "jnunemaker@rubyforge.org:/var/www/gforge-projects/#{ProjectName}"

require 'rubygems'
require 'rake'
require 'echoe'
require 'spec/rake/spectask'
require "lib/#{ProjectName}/version"

Echoe.new(ProjectName, HappyMapper::Version) do |p|
  p.description     = "object to xml mapping library"
  p.install_message = "May you have many happy mappings!"
  p.url             = "http://#{ProjectName}.rubyforge.org"
  p.author          = "John Nunemaker"
  p.email           = "nunemaker@gmail.com"
  p.extra_deps      = [['libxml-ruby', '>= 0.9.8']]
  p.need_tar_gz     = false
  p.docs_host       = WebsitePath
end

desc 'Upload website files to rubyforge'
task :website do
  sh %{rsync -av website/ #{WebsitePath}}
  Rake::Task['website_docs'].invoke
end

task :website_docs do
  Rake::Task['redocs'].invoke
  sh %{rsync -av doc/ #{WebsitePath}/docs}
end

desc 'Preps the gem for a new release'
task :prepare do
  %w[manifest build_gemspec].each do |task|
    Rake::Task[task].invoke
  end
end

Rake::Task[:default].prerequisites.clear
task :default => :spec
Spec::Rake::SpecTask.new do |t|
  t.spec_files = FileList["spec/**/*_spec.rb"]
end