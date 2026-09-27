require "pennycress"

class DiscussionTitle < Pennycress::Value
  class << self
    attr_accessor :compute_calls
  end

  self.compute_calls = 0

  input :discussion
  output String

  seeds { Discussion.pluck(:id) }

  watch :discussion do |discussion|
    [{ discussion: discussion }]
  end

  def compute(discussion:)
    self.class.compute_calls += 1
    discussion.title
  end

  def seed_to_inputs(id)
    [{ discussion: Discussion.find(id) }]
  end
end
