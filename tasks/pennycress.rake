# frozen_string_literal: true

require_relative "task_helpers/release"

namespace :pennycress do
  namespace :publish do
    desc "Populate the changelog with merge commits since the last release"
    task :changelog, [:version] do |_, args|
      version = args[:version]

      if version.nil? || version.empty?
        abort "Version is required (e.g. rake 'pennycress:publish:changelog[0.1.0]')"
      end

      unless version.match?(/\A\d+\.\d+\.\d+\z/)
        abort "Version must be a semver number like 0.1.0"
      end

      Pennycress::TaskHelpers::Release.update_changelog(version)
      puts "Updated CHANGELOG.md for #{version}"
    end

    desc "Print GitHub release notes for a version from CHANGELOG.md"
    task :release_notes, [:version] do |_, args|
      version = args[:version]

      if version.nil? || version.empty?
        abort "Version is required (e.g. rake 'pennycress:publish:release_notes[0.1.0]')"
      end

      unless version.match?(/\A\d+\.\d+\.\d+\z/)
        abort "Version must be a semver number like 0.1.0"
      end

      puts Pennycress::TaskHelpers::Release.build_release_notes(version)
    end
  end
end
