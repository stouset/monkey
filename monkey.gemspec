# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{monkey}
  s.version = "0.6.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Stephen Touset"]
  s.date = %q{2010-07-12}
  s.email = %q{stephen@touset.org}
  s.extra_rdoc_files = ["README.rdoc"]
  s.files = ["Rakefile", "README.rdoc", "VERSION", "lib/monkey/ext/modexcl/mrimodexcl.rb", "lib/monkey/ext/modexcl/rbmodexcl.rb", "lib/monkey/ext/modexcl/rbxmodexcl.rb", "lib/monkey.rb"]
  s.rdoc_options = ["--main", "README.rdoc"]
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.3.7}
  s.summary = %q{A smart, scoped monkeypatching library}

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_development_dependency(%q<version>, [">= 0"])
      s.add_development_dependency(%q<rspec>, [">= 0"])
    else
      s.add_dependency(%q<version>, [">= 0"])
      s.add_dependency(%q<rspec>, [">= 0"])
    end
  else
    s.add_dependency(%q<version>, [">= 0"])
    s.add_dependency(%q<rspec>, [">= 0"])
  end
end
