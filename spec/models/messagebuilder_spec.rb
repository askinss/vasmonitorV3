require 'spec_helper'
describe Messagebuilder do
  describe 'build_message for daily' do
   it "should have h3 tags" do
     active_and_deactivated = Hash.new
     active_and_deactivated.merge!(Subscriber.total_active("from_oracle"))
     active_and_deactivated.merge!(Subscriber.total_deactivated("from_oracle"))
     active_and_deactivated.merge!(Subscriber.total("from_oracle"))
     others = Hash.new
     others.merge!(Subscriber.fresh_activation("from_oracle"))
     others.merge!(Subscriber.renewal("from_oracle"))
     others.merge!(Subscriber.total_activation("from_oracle"))
     others.merge!(Subscriber.total_deactivation("from_oracle"))
     Messagebuilder.build_message(Oraclequery.new.shortcodes, active_and_deactivated, others).should include('h3')
   end 
  end

  describe 'build_message for weekly' do
   it "should have include last week" do
     active_and_deactivated = Hash.new
     others = Hash.new
     active_and_deactivated.merge!(Subscriber.send(("total_active" + "_weekly").to_sym, "from_oracle"))
     active_and_deactivated.merge!(Subscriber.send(("total_deactivated" + "_weekly").to_sym,"from_oracle"))
     active_and_deactivated.merge!(Subscriber.send(("total" + "_weekly").to_sym,"from_oracle"))
     others.merge!(Subscriber.send(("fresh_activation" + "_weekly").to_sym,"from_oracle"))
     others.merge!(Subscriber.send(("renewal" + "_weekly").to_sym,"from_oracle"))
     others.merge!(Subscriber.send(("total_activation" + "_weekly").to_sym,"from_oracle"))
     others.merge!(Subscriber.send(("total_deactivation" + "_weekly").to_sym,"from_oracle"))
     Messagebuilder.build_message(Oraclequery.new.shortcodes, active_and_deactivated, others, "weekly").should include(last_week)
   end
  end

  describe 'build_message for monthly' do
   it "should have include last month" do
     active_and_deactivated = Hash.new
     others = Hash.new
     active_and_deactivated.merge!(Subscriber.send(("total_active" + "_monthly").to_sym, "from_oracle"))
     active_and_deactivated.merge!(Subscriber.send(("total_deactivated" + "_monthly").to_sym,"from_oracle"))
     active_and_deactivated.merge!(Subscriber.send(("total" + "_monthly").to_sym,"from_oracle"))
     others.merge!(Subscriber.send(("fresh_activation" + "_monthly").to_sym,"from_oracle"))
     others.merge!(Subscriber.send(("renewal" + "_monthly").to_sym,"from_oracle"))
     others.merge!(Subscriber.send(("total_activation" + "_monthly").to_sym,"from_oracle"))
     others.merge!(Subscriber.send(("total_deactivation" + "_monthly").to_sym,"from_oracle"))
     Messagebuilder.build_message(Oraclequery.new.shortcodes, active_and_deactivated, others, "monthly").should include(last_month_to_s)
   end
  end
end
