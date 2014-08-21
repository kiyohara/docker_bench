require_relative './command_output_parser'

=begin
----- mpstat ----->
Linux 3.13.0-32-generic (meti-sd-bench)   08/20/2014  _x86_64_  (2 CPU)

08:18:54 PM  CPU    %usr   %nice    %sys %iowait    %irq   %soft  %steal  %guest  %gnice   %idle
08:18:54 PM  all    1.85    0.00    3.07    0.02    0.17    0.00    0.00    0.00    0.00   94.89
----- mpstat -----<
=end

class MpstatOutputParser
  include CommandOutputParser

  def separator_word
    "mpstat"
  end

  def regexp_parse
    /all\s+([\d\.]+)\s+[\d\.]+\s+([\d\.]+)\s+[\d\.]+\s+[\d\.]+\s+[\d\.]+\s+[\d\.]+\s+[\d\.]+\s+[\d\.]+\s+[\d\.]+$/
  end

  def headers
    [ "cpu_usr", "cpu_sys" ]
  end

  def sqlite_col_types
    [ 'float', 'float' ]
  end
end
