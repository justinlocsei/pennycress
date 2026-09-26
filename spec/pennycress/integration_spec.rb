# frozen_string_literal: true

require "active_support/core_ext/string/inflections"
require "active_record"
require "fileutils"
require "tmpdir"
require "pennycress/integration"
require "pennycress/value"

RSpec.describe Pennycress::Integration do
  describe ".handle_commit" do
    it "evicts cached outputs for derived inputs" do
      discussion = Class.new(ActiveRecord::Base) do
        attr_accessor :id
      end

      stub_const("Discussion", discussion)
      compute_calls = 0

      value = Class.new(Pennycress::Value) do
        input id: Integer
        output Integer

        define_method(:compute) do |id:|
          compute_calls += 1
          id
        end

        watch :discussion do |record|
          [{ id: record.id }]
        end
      end

      with_memory_cache do
        described_class.watch_models

        value.fetch(id: 1)
        expect(compute_calls).to eq(1)

        record = discussion.allocate
        record.id = 1

        described_class.handle_commit(record)

        value.fetch(id: 1)
        expect(compute_calls).to eq(2)
      end
    end
  end

  describe ".load_values" do
    it "raises when a path does not exist" do
      path = "/pennycress/missing"

      expect {
        described_class.load_values([path])
      }.to raise_error(ArgumentError, "path is not a directory: #{path}")
    end

    context "with value files in nested directories" do
      let(:root) { Dir.mktmpdir }
      let(:base) { "IntegrationSpecValue#{SecureRandom.hex(4)}" }
      let(:class_names) { 3.times.map { |index| "#{base}#{index}" } }
      let(:directories) { 3.times.map { |index| File.join(root, "group_#{index}") } }

      before do
        class_names.each_with_index do |class_name, index|
          directory = File.join(directories[index], "nested")
          FileUtils.mkdir_p(directory)

          File.write(
            File.join(directory, "#{class_name.underscore}.rb"),
            <<~RUBY
              class #{class_name} < Pennycress::Value
                input id: Integer
                output Integer
              end
            RUBY
          )
        end
      end

      after do
        FileUtils.remove_entry(root)
      end

      it "loads value classes from a single root" do
        described_class.load_values([root])

        loaded = Pennycress::Registry.current.values.map(&:name)
        expect(loaded).to include(*class_names)
      end

      it "loads value classes from multiple roots" do
        described_class.load_values(directories)

        loaded = Pennycress::Registry.current.values.map(&:name)
        expect(loaded).to include(*class_names)
      end
    end
  end

  describe ".watch_models" do
    it "installs commit handlers on watched models" do
      discussion = Class.new(ActiveRecord::Base)
      stub_const("Discussion", discussion)

      Class.new(Pennycress::Value) do
        input id: Integer
        output Integer

        watch :discussion do |record|
          [{ id: record.id }]
        end
      end

      described_class.watch_models

      expect(discussion.included_modules).to include(Pennycress::Integration::ModelCommitHandler)
    end
  end
end
