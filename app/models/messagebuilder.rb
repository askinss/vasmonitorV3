class Messagebuilder
  include Airtel
  def self.build_message(*args)
    message = "<h3 style=\"color:blue;text-align:center;font:5px\">#{args[2].upcase} ACTIVE AND DEACTIVATED SUBSCRIBERS AT #{Time.now.strftime("%Y-%m-%d %H:%M:%S")}</h3>"
    message << Tablegenerator.new(args[0],args[1]).generate_table
    message << ("<br />" * 3)
    if args.size == 4 
      message << "<h3 style=\"color:blue;text-align:center;font:5px\">#{args[2].upcase}  SUMMARY of PROVISIONING for #{yesterday}</h3>"
      message << Tablegenerator.new(args[0],args[3]).generate_table
    elsif (args.size == 5) && (args[4] == "weekly")
      message << "<h3 style=\"color:blue;text-align:center;font:5px\">#{args[2].upcase}  SUMMARY of PROVISIONING for  #{last_week}</h3>"
      message << Tablegenerator.new(args[0],args[3]).generate_table
    elsif (args.size == 5) && (args[4] == "monthly")
      message << "<h3 style=\"color:blue;text-align:center;font:5px\">#{args[2].upcase}  SUMMARY of PROVISIONING for  #{last_month_to_s}</h3>"
      message << Tablegenerator.new(args[0],args[3]).generate_table
    end
    message << ("<br />" * 3)
    message
  end
end
