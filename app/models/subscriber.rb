class Subscriber
  def self.method_missing(method, *arg)
    begin
      if (arg[0].gsub("from_","") == 'oracle')
        shortcodes = Oraclequery.new.shortcodes
      elsif (arg[0].gsub("from_","") == 'mysql')
        shortcodes = Mysqlquery.new.shortcodes
      end

      h = Hash.new
      if method.to_s.include?("weekly")
        arr = shortcodes.map { |shortcode| Report.sum_of_hash(7, shortcode.to_sym, method.to_s.gsub("_weekly","")) }
        h[method.to_s.gsub("_weekly","").to_sym] = arr
        h
      elsif method.to_s.include?("monthly")
        arr = shortcodes.map { |shortcode| Report.sum_of_hash(30, shortcode.to_sym, method.to_s.gsub("_monthly","")) }
        h[method.to_s.gsub("_monthly","").to_sym] = arr
        h
      elsif (arg[0].gsub("from_","") == 'oracle') && (arg.size == 1)
        arr = shortcodes.map { |shortcode| Oraclequery.new.send(method.to_sym)[shortcode].nil? ? 0 : Oraclequery.new.send(method.to_sym)[shortcode] }
        h[method.to_sym] = arr
        h
      elsif (arg[0].gsub("from_","") == "mysql") && (arg.size == 1)
        arr = shortcodes.map { |shortcode| Mysqlquery.new.send(method.to_sym)[shortcode].nil? ? 0 : Mysqlquery.new.send(method.to_sym)[shortcode] }
        h[method.to_sym] = arr
        h
      elsif (arg[0].gsub("from_","") == 'mysql') && arg[1] == "to_mongo"
        a = Mysqlquery.new.send(method.to_sym)
        a[:description] = method.to_s
        begin
          Report.create!(a)
        rescue => e
          e.backtrace
        end
      elsif (arg[0].gsub("from_","") == 'oracle') && arg[1] == "to_mongo"
        a = Oraclequery.new.send(method.to_sym)
        a[:description] = method.to_s
        begin
          Report.create!(a)
        rescue => e
          e.backtrace
        end
      end
    rescue
      super
    end
  end
end
