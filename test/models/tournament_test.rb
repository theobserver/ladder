require "minitest_helper"

describe Tournament do
  describe "#has_user?" do
    before do
      @tournament = FactoryGirl.create(:tournament)
      @users = FactoryGirl.create_list(:user, 2)
      @rank = FactoryGirl.create(:rank, :user => @users.first, :tournament => @tournament)
    end

    it "must match users who are participating" do
      @tournament.has_user?(@users.first).must_equal true
    end

    it "wont match users who are not participating" do
      @tournament.has_user?(@users.last).must_equal false
    end
  end
end
