sphere-cli
==========

The Command Line Interface (CLI) to [Sphere.IO](http://sphere.io)

Have a look at the [developer documentation](http://dev.sphere.io/CLI.html)

## Development

[![Build Status](https://travis-ci.org/commercetools/sphere-cli.png)](https://travis-ci.org/commercetools/sphere-cli)

Getting started by using `bundler` to get all necessary dependencies:
```
gem install bundler
bundle
```

### Run tests

Sphere CLI provides two kind of tests:
- RSpec based tests that mock the backend
- Acceptance test using cucumber/aruba

```
rake rspec # unit tests
rake cucucmber # acceptance test
```

#### Run tests automatically on code changes

Sphere CLI uses guard to execute rspec tests and some cucumber features to run everytime you save some files.
Execute the following command in a separate terminal:
```
bundle exec guard
```

Guard will only execute those cucumber features that do not run against the backend.
