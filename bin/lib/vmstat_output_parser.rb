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

  def headers
    [ "mem_free" ]
  end

  def sqlite_col_types
    [ 'int' ]
  end
end
