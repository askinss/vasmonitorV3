require 'spec_helper'
describe Subscriber do
  describe 'total_active' do
    it "should return an hash in the form {:description => array of counts of shortcodes" do
      Subscriber.total_active("from_oracle").should be_an_instance_of Hash
    end

    it "should have its key as total_active" do
      Subscriber.total_active("from_oracle").should have_key("total_active".to_sym)
    end

    it "should have a value of an array" do
      Subscriber.total_active("from_oracle")[:total_active].should be_an_instance_of Array
    end

    it "should have a value of an array of its length same as the number of shortcodes" do
      Subscriber.total_active("from_oracle")[:total_active].size.should eq(Oraclequery.new.shortcodes.size)
    end
  end

  describe 'total_deactivated' do
    it "should return an hash in the form {:description => array of counts of shortcodes" do
      Subscriber.total_deactivated("from_oracle").should be_an_instance_of Hash
    end

    it "should have its key as total_deactivated" do
      Subscriber.total_deactivated("from_oracle").should have_key("total_deactivated".to_sym)
    end

    it "should have a value of an array" do
      Subscriber.total_deactivated("from_oracle")[:total_deactivated].should be_an_instance_of Array
    end

    it "should have a value of an array of its length same as the number of shortcodes" do
      Subscriber.total_deactivated("from_oracle")[:total_deactivated].size.should eq(Oraclequery.new.shortcodes.size)
    end
  end

  describe 'total_activation' do
    it "should return an hash in the form {:description => array of counts of shortcodes" do
      Subscriber.total_activation("from_oracle").should be_an_instance_of Hash
    end

    it "should have its key as total_activation" do
      Subscriber.total_activation("from_oracle").should have_key("total_activation".to_sym)
    end

    it "should have a value of an array" do
      Subscriber.total_activation("from_oracle")[:total_activation].should be_an_instance_of Array
    end

    it "should have a value of an array of its length same as the number of shortcodes" do
      Subscriber.total_activation("from_oracle")[:total_activation].size.should eq(Oraclequery.new.shortcodes.size)
    end
  end

  describe 'total_deactivation' do
    it "should return an hash in the form {:description => array of counts of shortcodes" do
      Subscriber.total_deactivation("from_oracle").should be_an_instance_of Hash
    end

    it "should have its key as total_deactivation" do
      Subscriber.total_deactivation("from_oracle").should have_key("total_deactivation".to_sym)
    end

    it "should have a value of an array" do
      Subscriber.total_deactivation("from_oracle")[:total_deactivation].should be_an_instance_of Array
    end

    it "should have a value of an array of its length same as the number of shortcodes" do
      Subscriber.total_deactivation("from_oracle")[:total_deactivation].size.should eq(Oraclequery.new.shortcodes.size)
    end
  end

  describe 'total' do
    it "should return an hash in the form {:description => array of counts of shortcodes" do
      Subscriber.total("from_oracle").should be_an_instance_of Hash
    end

    it "should have its key as total" do
      Subscriber.total("from_oracle").should have_key("total".to_sym)
    end

    it "should have a value of an array" do
      Subscriber.total("from_oracle")[:total].should be_an_instance_of Array
    end

    it "should have a value of an array of its length same as the number of shortcodes" do
      Subscriber.total("from_oracle")[:total].size.should eq(Oraclequery.new.shortcodes.size)
    end
  end

  describe 'total_activation "from_oracle" "to_mongo"' do
    it "should create a new mongodb object by accepting to_mongo as an param and supplying  " do
      a = Subscriber.total_activation("from_oracle", "to_mongo")
      a.should be_an_instance_of Report
    end
  end

  describe 'fresh_activation "from_oracle" "to_mongo"' do
    it "should create a new mongodb object by accepting to_mongo as an param and supplying  " do
      a = Subscriber.fresh_activation("from_oracle", "to_mongo")
      a.should be_an_instance_of Report
    end
  end

  describe 'total_weekly' do
    it "should return an hash in the form {:description => sum of counts of shortcodes" do
      Subscriber.total_weekly.should be_an_instance_of Hash
    end
    it "should have a value of an array of its length same as the number of shortcodes" do
      Subscriber.total_weekly[:total].size.should eq(Oraclequery.new.shortcodes.size)
    end
  end

  describe 'renewal_monthly' do
    it "should return an hash in the form {:description => sum of counts of shortcodes" do
      Subscriber.renewal_monthly.should be_an_instance_of Hash
    end
    it "should have a value of an array of its length same as the number of shortcodes" do
      Subscriber.renewal_monthly[:renewal].size.should eq(Oraclequery.new.shortcodes.size)
    end
  end
end
