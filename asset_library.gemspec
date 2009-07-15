# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{asset_library}
  s.version = "0.1.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["adamh"]
  s.date = %q{2009-07-15}
  s.email = %q{adam@adamhooper.com}
  s.extra_rdoc_files = [
    "README.rdoc"
  ]
  s.files = [
    "lib/asset_library.rb",
     "lib/asset_library/asset.rb",
     "lib/asset_library/asset_module.rb",
     "lib/asset_library/helpers.rb",
     "lib/asset_library/rake_tasks.rb",
     "lib/asset_library/util.rb",
     "rails/init.rb"
  ]
  s.has_rdoc = true
  s.homepage = %q{http://github.com/adamh/asset_library}
  s.rdoc_options = ["--charset=UTF-8"]
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.3.1}
  s.summary = %q{Manage and bundle CSS and JavaScript files}
  s.test_files = [
    "spec/asset_library_spec.rb",
     "spec/asset_library/asset_spec.rb",
     "spec/asset_library/helpers_spec.rb",
     "spec/asset_library/asset_module_spec.rb",
     "spec/spec_helper.rb"
  ]

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 2

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
    else
    end
  else
  end
end
