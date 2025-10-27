# Publishing mythic-beasts to RubyGems

## Prerequisites

1. **RubyGems Account**
   - Create account at https://rubygems.org
   - Verify email address

2. **API Key**
   ```bash
   # Login to RubyGems (one-time setup)
   gem signin
   ```

## Pre-publish Checklist

- ✅ All tests passing: `bundle exec rake test`
- ✅ StandardRB clean: `bundle exec standardrb`
- ✅ Version updated in `lib/mythic_beasts/version.rb`
- ✅ CHANGELOG.md updated with changes
- ✅ README.md is current
- ✅ GitHub repository created at https://github.com/tastybamboo/mythic-beasts

## Publishing Steps

### 1. Final Verification

```bash
cd mythic-beasts

# Run full test suite
bundle exec rake test

# Check gem builds cleanly
gem build mythic-beasts.gemspec
```

### 2. Test Local Installation

```bash
# Install locally to test
gem install ./mythic-beasts-0.1.0.gem

# Test in a Ruby console
irb
> require 'mythic_beasts'
> MythicBeasts::VERSION
```

### 3. Push to RubyGems

```bash
# Push to RubyGems
gem push mythic-beasts-0.1.0.gem
```

### 4. Verify Publication

Visit: https://rubygems.org/gems/mythic-beasts

### 5. Create GitHub Release

```bash
# Tag the release
git tag -a v0.1.0 -m "Release version 0.1.0"
git push origin v0.1.0

# Create release on GitHub
gh release create v0.1.0 --title "v0.1.0" --notes "Initial release - See CHANGELOG.md for details"
```

## Post-publication

### Update neurobetter-infrastructure

```bash
cd neurobetter-infrastructure

# Update Gemfile to use published gem
cp Gemfile.production Gemfile

# Update bundle
bundle update mythic-beasts

# Commit changes
git add Gemfile Gemfile.lock
git commit -m "Update to published mythic-beasts gem v0.1.0"
```

### Announce

- Tweet about the release
- Post to Reddit (r/ruby)
- Update tastybamboo website/blog
- Add to Awesome Ruby lists

## Subsequent Releases

1. Update version in `lib/mythic_beasts/version.rb`
2. Update CHANGELOG.md
3. Run tests and linting
4. Commit changes: `git commit -m "Bump version to X.Y.Z"`
5. Build and push gem
6. Create git tag and GitHub release

## Version Numbers

Follow [Semantic Versioning](https://semver.org/):

- **MAJOR** (1.0.0): Breaking changes
- **MINOR** (0.2.0): New features, backwards compatible
- **PATCH** (0.1.1): Bug fixes, backwards compatible

## Author

**James Inman** ([@jfi](https://github.com/jfi))
- Email: james@otaina.co.uk
- GitHub: https://github.com/tastybamboo

## Copyright

Copyright (c) 2025 Otaina Limited
