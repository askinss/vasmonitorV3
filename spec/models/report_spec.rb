require 'spec_helper'
describe Report do
  describe ".report_hash" do
    it "returns reports generated " do
      pending
    end

    it "includes report generated in the past one month" do
      pending
    end

  end

  describe "sum_of_hash" do
    it "should return the sum of counts for plan wrt description" do
      Report.sum_of_hash(7, :PrepaidProsumerB_7, "fresh_activation").should be_an_instance_of Fixnum
    end

    it "should return 0 for plans not found" do
      Report.sum_of_hash(7, :Prosume_30, "fresh_activation").should eq(0)
    end
  end
end
