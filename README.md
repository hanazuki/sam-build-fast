# sam-build-fast

A fast alternative for `sam build`, which speeds up the builds with caching.

## Usage
### CLI

Run `sam-build-fast` instead of `sam build`.

### Rake

```ruby
require 'sam-build-fast/rake'

task :default => :'sam:build'
SamBuildFast::Rake.define(:sam)
```
