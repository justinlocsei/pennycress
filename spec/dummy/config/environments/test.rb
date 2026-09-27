Rails.application.configure do
  config.enable_reloading = false
  config.eager_load = false
  config.cache_store = :memory_store
  config.active_job.queue_adapter = :test
  config.active_support.deprecation = :stderr
end
