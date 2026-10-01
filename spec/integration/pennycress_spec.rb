# frozen_string_literal: true

RSpec.describe "Pennycress", type: :integration do
  it "exposes a version" do
    expect(Pennycress::VERSION).to be_a(String)
  end

  it "supports configuration" do
    described_class.configure do |config|
      expect(config).to equal(Pennycress::Configuration.current)
    end
  end

  it "automatically discovers value classes" do
    expect(Pennycress::Registry.current.values.map(&:name)).to include("DiscussionTitle")
  end

  it "uses the Rails cache by default" do
    expect(Pennycress::Configuration.current.cache).to equal(Rails.cache)
  end

  it "evicts cached value outputs after an input model is changed" do
    discussion = Discussion.create!(title: "Alfa")

    expect(DiscussionTitle.fetch(discussion: discussion)).to eq("Alfa")
    expect(DiscussionTitle.compute_calls).to eq(1)

    discussion.update!(title: "Bravo")

    expect(DiscussionTitle.fetch(discussion: discussion)).to eq("Bravo")
    expect(DiscussionTitle.compute_calls).to eq(2)
  end

  it "fetches by primary key value without loading the model on a cache hit" do
    discussion = Discussion.create!(title: "Alfa")
    allow(Discussion).to receive(:find).and_call_original

    expect(DiscussionTitle.fetch(discussion: discussion.id)).to eq("Alfa")
    expect(DiscussionTitle.fetch(discussion: discussion.id)).to eq("Alfa")
    expect(DiscussionTitle.compute_calls).to eq(1)
    expect(Discussion).to have_received(:find).once
  end

  it "supports synchronous cache warming" do
    discussion = Discussion.create!(title: "Alfa")

    Pennycress.warm_cache(async: false)

    expect(DiscussionTitle.compute_calls).to eq(1)
    expect(DiscussionTitle.fetch(discussion: discussion)).to eq("Alfa")
    expect(DiscussionTitle.compute_calls).to eq(1)
  end

  it "supports asynchronous cache warming" do
    alfa = Discussion.create!(title: "Alfa")
    bravo = Discussion.create!(title: "Bravo")

    Rails.application.load_tasks

    task = Rake::Task["pennycress:warm_cache"]
    task.reenable

    expect { task.invoke }.to change { enqueued_jobs.size }.by(2)

    expect(enqueued_jobs.map { |job| job[:args] }).to contain_exactly(
      ["DiscussionTitle", alfa.id],
      ["DiscussionTitle", bravo.id]
    )
  end
end
