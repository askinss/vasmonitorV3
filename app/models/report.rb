class Report
  include Airtel
  include Mongoid::Document
  include Mongoid::Timestamps::Created

  def self.report_hash(no_of_days, shortcode, provisioning_type)
    hash_of_report = {}
    array_of_counts = []
    iterator = 0
    start_date = 0
    self.where(created_at: { '$gte' => (Time.now - no_of_days.to_i * 86400), '$lte' => Time.now }, description: provisioning_type).each do |x| 
      (array_of_counts << x.attributes[shortcode.to_s])
      start_date = (x.created_at.to_i - 86400) if (iterator == 0)
      iterator += 1
    end
    hash_of_report[shortcode] = [start_date,array_of_counts]
    hash_of_report
  end

  def self.sum_of_hash(no_of_days, shortcode, description)
    begin
      Report.where(created_at: { '$gte' => (Time.now - no_of_days.to_i * 86400), '$lte' => Time.now }, description: description).sum(shortcode.to_sym).to_i
    rescue => e 
      e.backtrace
      return 0
    end
  end

  def self.provisioning_type
    self.all.map do |x|
      begin
        x.description.gsub("_"," ").upcase 
      rescue NoMethodError
        next
      end
    end.uniq
  end

end
