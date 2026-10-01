# frozen_string_literal: true

require_relative "task_helpers/version"
require_relative "task_helpers/release"

namespace :pennycress do
  namespace :publish do
    desc "Populate the changelog with merge commits since the last release"
    task :changelog, [:version] do |_, args|
      version = Pennycress::TaskHelpers.require_version(args[:version])

      Pennycress::TaskHelpers::Release.update_changelog(version)

      puts "Updated CHANGELOG.md for #{version}"
    end

    desc "Print GitHub release notes for a version from CHANGELOG.md"
    task :release_notes, [:version] do |_, args|
      puts Pennycress::TaskHelpers::Release.build_release_notes(
        Pennycress::TaskHelpers.require_version(args[:version])
      )
    end
  end
end
