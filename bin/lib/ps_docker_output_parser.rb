require_relative './ps_output_parser'

=begin
----- ps docker.io daemon ----->
root     60642  5.0  0.1 341276 10088 ?        Ssl  20:18   0:00 /usr/bin/docker -d
----- ps docker.io daemon -----<
=end

class PsDockerOutputParser
  include PsOutputParser

  def separator_word
    "ps docker.io daemon"
  end

  def parsed_headers
    [ 'docker_io_VSZ', 'docker_io_RSS' ]
  end

  def delta_headers
    [
      "docker_io_VSZ_all_delta",
      "docker_io_RSS_all_delta",
      "docker_io_VSZ_delta",
      "docker_io_RSS_delta",
      "docker_io_VSZ_delta_ave",
      "docker_io_RSS_delta_ave",
    ]
  end

  def calc_delta!(initial_data, prev_data, index)
    super

    docker_io_VSZ_all_delta = to_hash['docker_io_VSZ'] - initial_data.to_hash['docker_io_VSZ']
    docker_io_RSS_all_delta = to_hash['docker_io_RSS'] - initial_data.to_hash['docker_io_RSS']
    if prev_data
      docker_io_VSZ_delta = to_hash['docker_io_VSZ'] - prev_data.to_hash['docker_io_VSZ']
      docker_io_RSS_delta = to_hash['docker_io_RSS'] - prev_data.to_hash['docker_io_RSS']
    else
      docker_io_VSZ_delta = docker_io_VSZ_all_delta
      docker_io_RSS_delta = docker_io_RSS_all_delta
    end
    docker_io_VSZ_delta_ave = docker_io_VSZ_all_delta / index
    docker_io_RSS_delta_ave = docker_io_RSS_all_delta / index

    @delta_data = [
      docker_io_VSZ_all_delta,
      docker_io_RSS_all_delta,
      docker_io_VSZ_delta,
      docker_io_RSS_delta,
      docker_io_VSZ_delta_ave,
      docker_io_RSS_delta_ave,
    ]
  end
end
