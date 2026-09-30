# frozen_string_literal: true

require "open3"

module Pennycress
  module TaskHelpers
    module Release
      REPOSITORY_URL = "https://github.com/justinlocsei/pennycress"

      PRCommit = Data.define(:number, :title)

      class << self
        def build_release_notes(version, changelog_path: default_changelog_path)
          section = extract_section(File.read(changelog_path), version)

          section.gsub(/\[(#\d+)\]/, '\1')
        end

        def update_changelog(version, changelog_path: default_changelog_path)
          changelog = File.read(changelog_path)
          previous_version = extract_latest_version(changelog)
          commits = commits_since_tag(previous_version)

          updated = add_pr_references(
            add_version_reference(
              insert_version_section(changelog, version, commits),
              version,
              previous_version
            ),
            commits
          )

          File.write(changelog_path, updated)
        end

        def default_changelog_path
          File.expand_path("../../CHANGELOG.md", __dir__)
        end

        def extract_latest_version(changelog)
          match = changelog.match(/^## \[(\d+\.\d+\.\d+)\]/m)
          version = match&.[](1)

          raise "Could not determine the latest version from the changelog" unless version

          version.split(".").map(&:to_i).join(".")
        end

        def extract_pr_commit(subject)
          match = subject.match(/^(.+?)\s+\(#(\d+)\)$/)
          return unless match

          PRCommit.new(number: match[2].to_i, title: match[1])
        end

        def insert_version_section(changelog, version, commits)
          lines = changelog.split("\n")
          versions_at = lines.index { |line| line.match?(/^## \[[^\]]+\]/) }

          raise "No versions were found in the changelog" unless versions_at

          date = Time.now.utc.strftime("%Y-%m-%d")
          entries = commits.map { |commit| "- #{commit.title} ([#{commit.number}])" }

          [
            *lines[0...versions_at],
            "## [#{version}] (#{date})",
            "",
            *entries,
            "",
            *lines[versions_at..]
          ].join("\n")
        end

        def add_version_reference(changelog, version, previous_version)
          lines = changelog.split("\n")
          versions_at = lines.index("<!-- Versions -->")

          raise "Changelog versions footer not found" unless versions_at

          link = "[#{version}]: #{REPOSITORY_URL}/compare/v#{previous_version}..v#{version}"

          [
            *lines[0...(versions_at + 2)],
            link,
            *lines[(versions_at + 2)..]
          ].join("\n")
        end

        def add_pr_references(changelog, commits)
          prs = commits.sort_by(&:number).map do |commit|
            "[##{commit.number}]: #{REPOSITORY_URL}/pull/#{commit.number}"
          end

          "#{changelog.rstrip}\n#{prs.join("\n")}\n"
        end

        private

        def extract_section(changelog, version)
          heading = "## [#{version}]"
          lines = changelog.split("\n")
          start = lines.index { |line| line.start_with?(heading) }

          raise "No changelog section found for version #{version}" unless start

          body = []

          lines[(start + 1)..].each do |line|
            break if line.start_with?("## [") || line.start_with?("[") || line == "<!-- Versions -->"

            body << line
          end

          body.join("\n").strip
        end

        def commits_since_tag(previous_version)
          stdout, status = Open3.capture2(
            "git",
            "log",
            "v#{previous_version}..HEAD",
            "--format=%s"
          )

          raise "git log failed (is v#{previous_version} tagged?)" unless status.success?

          stdout.split("\n").filter_map { |subject| extract_pr_commit(subject) }
        end
      end
    end
  end
end
