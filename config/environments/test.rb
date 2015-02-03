MushroomObserver::Application.configure do
  # Settings specified here will take precedence over those in config/application.rb

  # ----------------------------
  #  MO configuration.
  # ----------------------------

  config.domain      = "mushroomobserver.org"
  config.http_domain = "http://mushroomobserver.org"

  # List of alternate server domains.  We redirect from each of these to the real one.
  config.bad_domains = ["www.mushroomobserver.org"]

  # Disable queued email.
  config.queue_email = false

  # Serve new images from local_images, old images from remote_images.
  # Transfer to two servers, both local, but one using ssh to do it.
  # Keep thumbnails locally, and only copy thumbnails to second server.
  config.local_image_files = "#{config.root}/public/test_images"
  config.image_sources = {
    :local => {
      :test => "file://#{config.local_image_files}",
      :read => "/local_images",
    },
    :remote1 => {
      :test  => :transferred_flag,
      :read  => "/remote_images",
      :write => "file://#{config.root}/public/test_server1"
    },
    :remote2 => {
      :write => "file://#{config.root}/public/test_server2",
      # Having trouble getting this to work on vagrant machine...
      # :write => "ssh://vagrant@localhost:#{config.root}/public/test_server2",
      :sizes => [ :thumbnail, :small, :medium ]
    }
  }
  config.image_precedence = {
    :default => [:local, :remote1 ]
  }
  config.image_fallback_source = :remote1
  config.keep_these_image_sizes_local = [ :thumbnail, :small ]

  config.robots_dot_text_file = "#{config.root}/test/fixtures/robots.txt"

  config.water_users = [1, 2]
  config.oil_users   = [4, 5]

  # ----------------------------
  #  Rails configuration.
  # ----------------------------

  # The test environment is used exclusively to run your application's
  # test suite.  You never need to work with it otherwise.  Remember that
  # your test database is "scratch space" for the test suite and is wiped
  # and recreated between test runs.  Don't rely on the data there!
  config.cache_classes = true

  # Log error messages when you accidentally call methods on nil.
  config.whiny_nils = true

  # Show full error reports and disable caching
  config.consider_all_requests_local       = true
  config.action_controller.perform_caching = false

  # Raise exceptions instead of rendering exception templates
  config.action_dispatch.show_exceptions = false

  # Disable request forgery protection in test environment
  config.action_controller.allow_forgery_protection = false

  # Tell Action Mailer not to deliver emails to the real world.
  # The :test delivery method accumulates sent emails in the
  # ActionMailer::Base.deliveries array.
  config.action_mailer.delivery_method = :test

  # Use SQL instead of Active Record's schema dumper when creating the test database.
  # This is necessary if your schema can't be completely dumped by the schema dumper,
  # like if you have constraints or database-specific column types
  # config.active_record.schema_format = :sql

  # Print deprecation notices to the stderr
  config.active_support.deprecation = :stderr

  # Configure static asset server for tests with Cache-Control for performance
  config.serve_static_assets = true
  config.static_cache_control = 'public, max-age=3600'

  # Compile and combine assets, but don't compress or add digests to names.
  config.assets.compile = true
  config.assets.compress = false
  config.assets.debug = false
  config.assets.digest = false

  # Raise exception on mass assignment protection for Active Record models
  config.active_record && config.active_record.mass_assignment_sanitizer = :strict
end

file = File.expand_path("../../consts-site.rb", __FILE__)
require file if File.exist?(file)
