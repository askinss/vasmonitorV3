class Report
  include Airtel
  include Mongoid::Document
  include Mongoid::Timestamps::Created

  def self.report_hash(no_of_days, shortcode, provisioning_type, rimservice_or_shortcode)
    (rimservice_or_shortcode = nil) if (rimservice_or_shortcode == "all")
    shortcode = rimservice_or_shortcode.to_s + shortcode
    hash_of_report = {}
    array_of_counts = []
    iterator = 0
    start_date = Report.asc(:created_at).where(created_at: { '$gte' => (Time.now - no_of_days.to_i * 86400) }, description: provisioning_type, rimservice_or_shortcode: rimservice_or_shortcode).each do |x| 
      (array_of_counts << x.attributes[shortcode.to_s])
    end.first.created_at.to_i - 86400
    hash_of_report[shortcode] = [start_date,array_of_counts]
    hash_of_report
  end

  def self.sum_of_hash(no_of_days, shortcode, description)
    begin
      Report.asc(:created_at).where(created_at: { '$gte' => (Time.now - no_of_days.to_i * 86400)}, description: description).sum(shortcode.to_sym).to_i
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

  def self.update_fields
    Report.all.each do |x| 
      if x.attributes.keys[10].include?("prepaid")
        x[:provisioning_type] = "prepaid"; x.save
      elsif x.attributes.keys[10].include?("shortcode")
        x[:provisioning_type] = "shortcode"; x.save
      end
    end
  end
end

