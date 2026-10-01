# frozen_string_literal: true

require "open3"

module Pennycress
  module TaskHelpers
    # This module provides methods for managing release documentation.
    module Release
      REPOSITORY_URL = "https://github.com/justinlocsei/pennycress"
      private_constant :REPOSITORY_URL

      PRCommit = Data.define(:number, :title)
      private_constant :PRCommit

      class << self
        # Build release notes from a version in the changelog
        #
        # @param version [String]
        # @return [String]
        def build_release_notes(version)
          extract_section(File.read(changelog_path), version)
            .gsub(/\[(#\d+)\]/, '\1')
        end

        # Update the changelog in place with notes on a new version
        #
        # @param version [String]
        # @return [void]
        def update_changelog(version)
          changelog = File.read(changelog_path)

          previous_version = extract_latest_version(changelog)
          commits = commits_since(previous_version)

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

      private

        # Add references to PR commits
        #
        # @param changelog [String]
        # @param commits [Array<PRCommit>]
        # @return [String]
        def add_pr_references(changelog, commits)
          prs = commits.sort_by(&:number).map do |commit|
            "[##{commit.number}]: #{REPOSITORY_URL}/pull/#{commit.number}"
          end

          "#{changelog.rstrip}\n#{prs.join("\n")}\n"
        end

        # Add a version-comparison link to the changelog
        #
        # @param changelog [String]
        # @param current [String] the new version
        # @param previous [String] the previous version
        # @return [String]
        def add_version_reference(changelog, current, previous)
          lines = changelog.split("\n")
          section_at = lines.index("<!-- Versions -->")

          raise "Could not find the versions section" unless section_at

          link = "[#{current}]: #{REPOSITORY_URL}/compare/v#{previous}..v#{current}"

          [
            *lines[0...(section_at + 2)],
            link,
            *lines[(section_at + 2)..]
          ].join("\n")
        end

        # @return [String] the path to the changelog
        def changelog_path
          @changelog_path ||= File.expand_path("../../CHANGELOG.md", __dir__)
        end

        # Get the commits since a previous version
        #
        # @param version [String]
        # @return [Array<PRCommit>]
        def commits_since(version)
          stdout, status = Open3.capture2(
            "git",
            "log",
            "v#{version}..HEAD",
            "--format=%s"
          )

          raise "Could not find commits since version #{version}" unless status.success?

          stdout
            .split("\n")
            .filter_map { |c| extract_pr_commit(c) }
        end

        # Extract the latest version from the changelog
        #
        # @param changelog [String]
        # @return [String]
        def extract_latest_version(changelog)
          match = changelog.match(/^## \[(\d+\.\d+\.\d+)\]/m)
          version = match&.[](1)

          raise "Could not determine the latest version from the changelog" unless version

          version
            .split(".")
            .map(&:to_i)
            .join(".")
        end

        # Extract a PR commit from a commit's subject line
        #
        # @param subject [String]
        # @return [PRCommit, nil]
        def extract_pr_commit(subject)
          match = subject.match(/^(.+?)\s+\(#(\d+)\)$/)
          match && PRCommit.new(number: match[2].to_i, title: match[1])
        end

        # Extract a version's section from the changelog
        #
        # @param changelog [String]
        # @param version [String]
        # @return [String]
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

        # Insert a version's section into the changelog
        #
        # @param changelog [String]
        # @param version [String]
        # @param commits [Array<PRCommit>]
        # @return [String]
        def insert_version_section(changelog, version, commits)
          lines = changelog.split("\n")
          versions_at = lines.index { |line| line.match?(/^## \[[^\]]+\]/) }

          raise "No versions were found in the changelog" unless versions_at

          date = Time.now.utc.strftime("%Y-%m-%d")
          entries = commits.map { |commit| "- #{commit.title} ([##{commit.number}])" }

          [
            *lines[0...versions_at],
            "## [#{version}] (#{date})",
            "",
            *entries,
            "",
            *lines[versions_at..]
          ].join("\n")
        end
      end
    end
  end
end
