# Release Management

Each Pennycress release involves a Git tag, GitHub release, and Ruby gem tied to a single commit.  Releases use a version number that follows semantic versioning.  In the workflow below, any instance of `<version>` is a placeholder that would be substituted with a value like `0.1.0` or `3.2.1` for an actual release.

## Workflow

To publish a new version of Pennycress, take the following steps:

1. Update `main` and create a release branch named `release/<version>`.
2. Run `git fetch --tags` to ensure that all previous release tags are available.
3. Run `rake 'pennycress:publish:changelog[<version>]'` to populate `CHANGELOG.md` with content for the new version.
4. Group the entries in the version's changelog section into Changes, Development, Features, or Fixes.
5. Update the `VERSION` constant in `lib/pennycress/version.rb` to use `<version>` as its value.
6. Run `bundle install` to refresh `Gemfile.lock`.
7. Commit all changed files with the message "Release `<version>`".
8. Push and open a PR against `main` with a title of "Release `<version>`" and a Release tag.
9. Wait for all CI tasks to pass.
10. Merge the PR.
11. Wait for [the Release workflow](https://github.com/justinlocsei/pennycress/actions/workflows/release.yml) to finish.
12. Run [the Verify Publishing workflow](https://github.com/justinlocsei/pennycress/actions/workflows/verify-publishing.yml) with the release's version number.
13. [Create a GitHub Release](https://github.com/justinlocsei/pennycress/releases/new) from the version tag (`v<version>`), using the tag as the title and the output of `rake 'pennycress:publish:release_notes[<version>]'` as the release notes.
