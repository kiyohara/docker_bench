require_relative './ps_output_parser'

=begin
----- ps container process ----->
USER       PID %CPU %MEM    VSZ   RSS TTY      STAT START   TIME COMMAND
root     49899  0.0  0.0   6504   628 ?        Ss   19:08   0:00 ping -c 20 127.0.0.1
----- ps container process ----->
=end

class PsContainerOutputParser
  include PsOutputParser

  def separator_word
    "ps container process"
  end

  def parsed_headers
    [ 'container_VSZ', 'container_RSS' ]
  end
end
