# frozen_string_literal: true

# Miscellaneous things that need to run before each spec.
RSpec.configure do |config|
  include ActiveJob::TestHelper

  # Time zone. There are many places where we Timecop.freeze in an around block, and this should happen first.
  config.around do |example|
    Time.zone = "UTC"
    example.run
  end

  config.around(perform_jobs: true) do |example|
    perform_enqueued_jobs { example.run }
    clear_enqueued_jobs
  end

  config.before do |example|
    Defaults.reset
    if example.metadata[:without_tenant]
      ActsAsTenant.current_tenant = nil
    else
      ActsAsTenant.current_tenant = Defaults.cluster
      Defaults.community
    end
  end

  config.before(type: :system) do
    OmniAuth.config.test_mode = false
  end

  config.before(type: :system) do
    clear_downloads
    set_host(Settings.url.host)
  end

  config.before(type: :request) do
    # Request specs may also use set_host, but not downloads.
    set_host(Settings.url.host)
  end
end
