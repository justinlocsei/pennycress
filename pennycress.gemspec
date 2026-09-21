# frozen_string_literal: true

require_relative "lib/pennycress/version"

Gem::Specification.new do |spec|
  spec.name = "pennycress"
  spec.version = Pennycress::VERSION
  spec.authors = ["Justin Locsei"]

  spec.summary = "Memoized domain values for Rails"
  spec.description = "Pennycress allows Rails apps to precompute and cache expensive logic, with fine-grained invalidation and support for targeted cache warming."
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.3.0"
  spec.metadata["rubygems_mfa_required"] = "true"

  spec.files = Dir.chdir(__dir__) do
    Dir.glob("{lib,sig}/**/*").select { |path| File.file?(path) }
  end

  spec.files += %w[LICENSE README.md]
  spec.require_paths = ["lib"]

  spec.add_dependency "rails", ">= 8.1"
end
