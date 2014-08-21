require_relative './command_output_parser'

=begin
----- time docker run ----->

real  0m0.212s
user  0m0.005s
sys   0m0.004s
----- time docker run -----<
=end

class TimeDockerRunOutputParser
  include CommandOutputParser

  def separator_word
    "time docker run"
  end

  def regexp_parse
    /real\s+([\d\.ms]+)$/
  end

  def convert(input)
    if md = input.match(/^(\d+)m([\d\.]+)s$/)
      md[1].to_i * 60 + md[2].to_f
    else
      input
    end
  end

  def headers
    [ 'time_docker_run' ]
  end

  def sqlite_col_types
    [ 'float' ]
  end
end
