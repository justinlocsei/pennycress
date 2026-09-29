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

      value = identity_value_class do
        watch :discussion do |record|
          [{ item: record.id }]
        end
      end

      with_memory_cache do
        described_class.watch_models

        value.fetch(item: 1)
        expect(value.compute_calls).to eq(1)

        record = discussion.allocate
        record.id = 1

        described_class.handle_commit(record)

        value.fetch(item: 1)
        expect(value.compute_calls).to eq(2)
      end
    end

    it "evicts cached outputs when a watched model is destroyed" do
      discussion = Class.new(ActiveRecord::Base) do
        attr_accessor :id

        def destroyed?
          true
        end
      end

      stub_const("Discussion", discussion)

      value = identity_value_class do
        watch :discussion do |record|
          [{ item: record.id }]
        end
      end

      with_memory_cache do
        described_class.watch_models

        value.fetch(item: 1)
        expect(value.compute_calls).to eq(1)

        record = discussion.allocate
        record.id = 1

        described_class.handle_commit(record)

        value.fetch(item: 1)
        expect(value.compute_calls).to eq(2)
      end
    end

    it "runs separate watches on the same model for different commit actions" do
      create_watch_runs = []
      destroy_watch_runs = []

      value = identity_value_class do
        watch :item, on: [:create] do |item|
          create_watch_runs << item
          [{ item: item.id }]
        end

        watch :item, on: [:destroy] do |item|
          destroy_watch_runs << item
          [{ item: item.id }]
        end
      end

      with_memory_cache do
        described_class.watch_models

        value.fetch(item: 3)
        value.fetch(item: 5)
        expect(value.compute_calls).to eq(2)

        created = Item.allocate
        allow(created).to receive_messages(id: 3, destroyed?: false, previously_new_record?: true)

        described_class.handle_commit(created)

        expect(create_watch_runs).to eq([created])
        expect(destroy_watch_runs).to be_empty

        value.fetch(item: 3)
        expect(value.compute_calls).to eq(3)
        value.fetch(item: 5)
        expect(value.compute_calls).to eq(3)

        create_watch_runs.clear

        destroyed = Item.allocate
        allow(destroyed).to receive_messages(id: 5, destroyed?: true, previously_new_record?: false)

        described_class.handle_commit(destroyed)

        expect(create_watch_runs).to be_empty
        expect(destroy_watch_runs).to eq([destroyed])

        value.fetch(item: 3)
        expect(value.compute_calls).to eq(3)
        value.fetch(item: 5)
        expect(value.compute_calls).to eq(4)
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
                input :item
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
        input :item
        output Integer

        watch :discussion do |record|
          [{ item: record.id }]
        end
      end

      described_class.watch_models

      expect(discussion.included_modules).to include(Pennycress::Integration::ModelCommitHandler)
    end
  end
end
