require_relative './command_output_parser'

=begin
----- vmstat ----->
procs -----------memory---------- ---swap-- -----io---- -system-- ------cpu-----
 r  b   swpd   free   buff  cache   si   so    bi    bo   in   cs us sy id wa st
 0  0      0 7545660 112816 165708    0    0     5    90  330  982  2  4 93  0  0
----- vmstat -----<
=end

class VmstatOutputParser
  include CommandOutputParser

  def separator_word
    "vmstat"
  end

  def regexp_parse
    /\d+\s+\d+\s+\d+\s+(\d+)\s+\d+\s+\d+\s+\d+\s+\d+\s+\d+\s+\d+/
  end

  def parsed_headers
    [ "mem_free" ]
  end

  def delta_headers
    [
      "mem_used_all_delta",
      "mem_used_container",
      "mem_used_container_ave",
    ]
  end

  def calc_delta!(initial_data, prev_data, index)
    super

    mem_used_all_delta = initial_data.to_hash['mem_free'] - to_hash['mem_free']
    if prev_data
      mem_used_per_container = prev_data.to_hash['mem_free'] - to_hash['mem_free']
    else
      mem_used_per_container = mem_used_all_delta
    end
    mem_used_container_ave = mem_used_all_delta / index

    @delta_data = [
      mem_used_all_delta,
      mem_used_per_container,
      mem_used_container_ave,
    ]
  end

  def sqlite_col_types
    [ 'int' ]
  end
end
