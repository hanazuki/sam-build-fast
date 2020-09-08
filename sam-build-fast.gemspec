Gem::Specification.new do |spec|
  spec.name = 'sam-build-fast'
  spec.version = '0.0.0'
  spec.authors = ['Kasumi Hanazuki']
  spec.email = ['kasumi@rollingapple.net']

  spec.summary = %q{A fast alternative for `sam build`}
  spec.description = %q{A fast alternative for `sam build`}
  spec.homepage = 'https://github.com/hanazuki/sam-build-fast'
  spec.license = 'MIT'

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = spec.homepage

  spec.files = Dir['{lib,bin}/**/*']
  spec.require_paths = ['lib']
  spec.bindir = 'bin'
  spec.executables = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
end
