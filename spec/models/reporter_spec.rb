require 'spec_helper'
describe Reportadapter do
  describe 'execute for yesterday' do
    it "should attempt to send an email" do
      Reportadapter.new.execute.should include(yesterday)
    end
  end
end
