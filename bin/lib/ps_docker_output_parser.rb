require_relative './command_output_parser'

=begin
----- ps docker.io daemon ----->
root     60642  5.0  0.1 341276 10088 ?        Ssl  20:18   0:00 /usr/bin/docker -d
----- ps docker.io daemon -----<
=end

class PsDockerOutputParser
  include CommandOutputParser

  def separator_word
    "ps docker.io daemon"
  end

  def regexp_parse
    /^\w+\s+\d+\s+[\d\.]+\s+[\d\.]+\s+(\d+)\s+(\d+)\s/
  end

  def headers
    [ 'docker_io_VSZ', 'docker_io_RSS' ]
  end

  def sqlite_col_types
    [ 'int', 'int' ]
  end
end
