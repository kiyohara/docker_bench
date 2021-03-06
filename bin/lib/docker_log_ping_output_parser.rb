require_relative './command_output_parser'

=begin
----- docker logs tail ----->
PING 127.0.0.1 (127.0.0.1) 56(84) bytes of data.
64 bytes from 127.0.0.1: icmp_seq=1 ttl=64 time=0.041 ms

--- 127.0.0.1 ping statistics ---
1 packets transmitted, 1 received, 0% packet loss, time 0ms
rtt min/avg/max/mdev = 0.041/0.041/0.041/0.000 ms
----- docker logs tail -----<
=end

class DockerLogPingOutputParser
  include CommandOutputParser

  def separator_word
    "docker logs tail"
  end

  def regexp_parse
    /icmp_seq=1 ttl=64 time=([\d\.]+)\sms/
  end

  def parsed_headers
    [ 'first_ping_rtt' ]
  end

  def sqlite_col_types
    [ 'float' ]
  end
end
