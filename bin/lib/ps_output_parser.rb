require_relative './command_output_parser'

=begin
root     60642  5.0  0.1 341276 10088 ?        Ssl  20:18   0:00 /usr/bin/docker -d
=end

module PsOutputParser
  include CommandOutputParser

  def regexp_parse
    /^\w+\s+\d+\s+[\d\.]+\s+[\d\.]+\s+(\d+)\s+(\d+)\s/
  end

  def parsed_headers
    [ 'VSZ', 'RSS' ]
  end

  def sqlite_col_types
    [ 'int', 'int' ]
  end
end
