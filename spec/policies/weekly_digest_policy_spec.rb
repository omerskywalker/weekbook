# frozen_string_literal: true

require "rails_helper"

RSpec.describe WeeklyDigestPolicy do
  let(:user) { create(:user) }
  let(:other_user) { create(:user) }
  let(:published_digest) { create(:weekly_digest, user: user, status: "published") }
  let(:draft_digest) { create(:weekly_digest, user: user, status: "draft") }

  describe "show?" do
    it "allows owner to see draft" do
      expect(described_class.new(user, draft_digest).show?).to be true
    end

    it "denies non-owner from seeing draft" do
      expect(described_class.new(other_user, draft_digest).show?).to be false
    end

    it "allows anyone to see published digest" do
      expect(described_class.new(other_user, published_digest).show?).to be true
    end

    it "allows unauthenticated user (nil) to see published digest" do
      expect(described_class.new(nil, published_digest).show?).to be true
    end
  end

  describe "edit?" do
    it "allows owner" do
      expect(described_class.new(user, draft_digest).edit?).to be true
    end

    it "denies non-owner" do
      expect(described_class.new(other_user, draft_digest).edit?).to be false
    end
  end
end
