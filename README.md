# Gather
A cohousing meals management system.

## Platform
Gather is a Ruby on Rails application with some client-side JavaScript for dynamic view elements. HTML is generally rendered server-side. [SCSS](http://sass-lang.com/) is used for styling. No special IDE is required for Ruby on Rails development.

Ruby on Rails applications are best developed and run on Linux, Unix, or Mac OS. Development is also possible, though not recommended, on Windows. See the [Rails download page](http://rubyonrails.org/download/) for more information.

## System Dependencies
To install the software below we recommend the following package managers:

- Mac OS X: [Homebrew](http://brew.sh/)
- Linux/Unix: bundled package manager (e.g. apt-get, yum)

For all environments:

1. Ruby (see [.ruby-version file](.ruby-version) for exact version, [rbenv](https://github.com/sstephenson/rbenv) is recommended for Ruby version management)
1. [Bundler](http://bundler.io/)
    1. Once Ruby is installed, run `gem install bundler` to install.
1. PostgreSQL v9.2+ (database)
1. ImageMagick v6.8+
1. Mailcatcher for testing email (run `gem install mailcatcher` to install).
    1. Note, this gem is deliberately not in the Gemfile because it is a standalone development tool.
1. A Gather OAuth client via the [Google API Console](https://support.google.com/cloud/answer/6158849?hl=en).

For development environments:

1. PhantomJS v2.1+

## Development Environment Setup
Follow these steps to setup a development environment for Gather.

1. Install all above dependencies

1. Retrieve project files using Git
    ```
    git clone https://github.com/sassafrastech/gather.git
    cd gather
    ```

    If developing, it's best to work off the development branch:
    ```
    git checkout develop
    ```

    The remaining steps should all be done from the project directory.

1. Install gems
    1. Run `bundle install` to install the required gems.

1. Set local config
    1. Copy `config/settings.local.yml.example` to `config/settings.local.yml`.
    1. Edit `config/settings.local.yml` to fit your environment.

1. Create development and test databases and schemas
    1. Copy `config/database.yml.example` to `config/database.yml`.
    1. Run `rake db:create` to create `gather_development` and `gather_test` databases.
    1. Run `rake db:schema:load` to create the schema in both databases.

1. Create some fake data and a user so you can sign in
    1. Run `rake fake:data` to add one cluster, one community, and a full complement of fake data. This command will also add a user with superadmin privileges with the Gmail address you entered in `settings.local.yml`.

1. Run the tests
    1. Run `bundle exec rspec`.
    1. All tests should pass.

1. Start the server
    1. Run `bundle exec rails s`.
    1. Leave this console open.

1. Start DelayedJob
    1. Open a new console.
    1. Go to the project directory.
    1. Run `bin/delayed_job start`.

1. Start using the system
    1. In a browser, go to `http://gather.localhost.tv:3000` to start Gather.
    1. Click "Sign in with Google" to use Gather as the user you just created.
    1. Enjoy!

## Linters
Linters are strongly recommended for checking your code. The CI system will run linters as well and pull requests won't be approved until all issues are resolved or cancelled by the reviewer.

### Setup
Several linters require `npm` to install. We recommend [using `nvm`](https://github.com/creationix/nvm#installation) to manage your Node/npm versions. Note that `nvm` does NOT shim Node executables so `nvm use` is required to load the right Node versions in each new shell session.

The below assume you have installed the Ruby and Node versions specified in `.ruby-version` and `.nvmrc` files, respectively.

Once you have `nvm` and Node installed, the following lines should give you all the required linters:

```
nvm use
npm install -g coffeelint@2.1.0
npm install -g eslint@4.17.0
npm install -g eslint-plugin-react@7.7.0
gem install rubocop -v 0.52.0
gem install scss_lint -v 0.56.0
```

### Running
To lint your code, simply run:

```
bin/lint
```

This will examine any modified or untracked files in your working copy.

To instead examine any new or modified files in your branch (not including uncommitted changes), run:

```
bin/lint --branch
```

The latter should be run before opening a pull request.

As part of an effort to clean up old code, you should try to resolve any linter errors in files you touch, unless there are an overwhelming number of them. At bare minimum, the _lines_ you touch should not have any lint.

### Tools

Most code editors have plugins for linting. They will identify and let you click directly into problematic lines. You are encouraged to try one out!
