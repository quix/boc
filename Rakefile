require_relative 'devel/levitate'
require 'rbconfig'

def config
  @s.developers << ["James M. Lawrence", "quixoticsycophant@gmail.com"]
  @s.username = "quix"
  @s.required_ruby_version = ">= 1.9.2"
  @s.dependencies << ["rake-compiler", "~> 0.7.6"]
  @s.rdoc_files = %w[
    lib/boc.rb
    lib/boc/version.rb
  ]
end

def mri_ext
  require 'rake/extensiontask'
    
  Rake::ExtensionTask.new @s.gem_name, binary_gemspec do |ext|
    ext.cross_compile = true
    ext.cross_platform = 'i386-mswin32'
    ext.lib_dir = "lib/#{@s.gem_name}"
  end
    
  # compensate for strange rake-compiler invocation
  task :cross_native_gem do
    Rake::Task[:gem].reenable
    Rake.application.top_level_tasks.replace %w[cross native gem]
    Rake.application.top_level
  end
    
  task :gem => :cross_native_gem
    
  task :test => so_file

  @s.gemspec.extensions = ["Rakefile"]
end

def jruby_ext
  require "rake/javaextensiontask"

  Levitate.no_warnings do
    Rake::JavaExtensionTask.new @s.gem_name, binary_gemspec do |ext|
      ext.ext_dir = "jext"
      ext.lib_dir = "lib/#{@s.gem_name}"
    end
  end

  task :jar => jar_file

  case RUBY_ENGINE
  when "jruby"
    task :test => jar_file
  when "ruby"
    # building/releasing from MRI

    task :jruby_gem => jar_file do
      # compensate for strange rake-compiler invocation
      Rake::Task[:gem].reenable
      Rake.application.top_level_tasks.replace %w[java gem]
      Rake.application.top_level
    end
    
    task :gem => :jruby_gem
    
    task :test_jruby do
      run_jruby = ENV["RUN_JRUBY"] || "jruby"
      cmd = run_jruby + " --1.9 -J-Djruby.astInspector.enabled=0 -S rake"
      sh(cmd + " test")
      sh(cmd + " test_deps")
    end
    
    task :prerelease => :test_jruby
    
    CLEAN.add jar_file 
  end
end

def jar_file
  # the only path jruby recognizes
  File.join("lib", @s.gem_name, @s.gem_name + ".jar")
end

def so_file
  File.join("lib", @s.gem_name, @s.gem_name + "." + RbConfig::CONFIG["DLEXT"])
end

def native_file
  case RUBY_ENGINE
  when "ruby"
    so_file
  when "jruby"
    jar_file
  end
end

def append_installer
  fu = FileUtils::Verbose

  source = native_file
  dir = File.join RbConfig::CONFIG["sitearchdir"], @s.gem_name
  dest = File.join dir, File.basename(source)

  task :install => source do
    fu.mkdir dir unless File.directory? dir
    fu.install source, dest
  end
  
  task :uninstall do
    fu.rm dest if File.file? dest
    fu.rmdir dir if File.directory? dir
  end
end

def config_extension
  case RUBY_ENGINE
  when "jruby"
    jruby_ext
  when "ruby"
    mri_ext
  else
    raise "sorry, platform `#{RUBY_ENGINE}' not supported"
  end
end

def binary_gemspec
  @s.gemspec.dup.tap do |gemspec|
    gemspec.dependencies.clear
    gemspec.add_development_dependency(*@s.dependencies.first)
  end
end

Levitate.new "boc" do |s|
  @s = s
  config
  if File.directory? ".git"
    mri_ext if RUBY_ENGINE == "ruby"
    jruby_ext
  elsif not File.file?(native_file)
    config_extension
  end
  append_installer
  task :finish_release do
    sh "gem", "push", "pkg/#{@s.gem_name}-#{@s.version}-java.gem"
    sh "gem", "push", "pkg/#{@s.gem_name}-#{@s.version}-x86-mswin32.gem"
  end
end
