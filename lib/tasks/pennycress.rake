# frozen_string_literal: true

namespace :pennycress do
  desc "Warm the cache for all values that define seeds"
  task warm_cache: :environment do
    Pennycress::Warming.warm_cache
  end
end
