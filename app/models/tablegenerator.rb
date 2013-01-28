class Tablegenerator
  def initialize(*args)
    @table = args
  end

  
  def header_builder
    "<th><b>Description</b></th><th style=\"color:red;text-align:left\"><b>#{(@table[0].map { |x| x.to_s.gsub("_", " ") }).join("</b><b></th><th style=\"color:red;text-align:left\">")}</b></th>"
  end

  def row_builder
    row = ""
    begin
      @table[1].each do |k,v|
        row << "<tr bgcolor=\"gray\"><td><b>#{k.to_s.gsub("_", " ").upcase}</b></td><td>#{v.join("</td><td>")}</td></tr>"
      end
     row
    rescue => e
      e.backtrace
      raise e
    end
  end

  def generate_table
    table = "<table style=\"width:100%;border:1px solid black;\">"
    table << header_builder
    table << row_builder
    table << "</table>"
  end

end
