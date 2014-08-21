require_relative './time_docker_run_output_parser'
require_relative './docker_log_ping_output_parser'
require_relative './mpstat_output_parser'
require_relative './vmstat_output_parser'
require_relative './ps_docker_output_parser'

class ContainerOutputParser
  def initialize(index=nil)
    @index = index

    @parsers = [
      TimeDockerRunOutputParser.new,
      DockerLogPingOutputParser.new,
      MpstatOutputParser.new,
      VmstatOutputParser.new,
      PsDockerOutputParser.new,
    ]

    @parser_crr = nil
  end

  def parse(line)
    @parsers.each do |parser|
      if parser.start_line?(line)
        @parser_crr = parser
      elsif @perser_crr && @perser_crr.end_line?(line)
        @perser_crr = nil
      end
    end

    @parser_crr.parse(line) if @parser_crr
  end

  def headers
    res = [ 'container_num' ]
    @parsers.each do |parser|
      res.concat(parser.headers)
    end
    res
  end

  def sqlite_table_defines
    res = [ 'container_num int' ]
    @parsers.each do |parser|
      res.concat(parser.sqlite_table_defines)
    end
    res
  end

  def sqlite_insert_defines
    res = [ '?' ]
    @parsers.each do |parser|
      res.concat(parser.sqlite_insert_defines)
    end
    res
  end

  def header
    headers.join(',')
  end

  def to_a
    res = [ @index ]
    @parsers.each do |parser|
      res.concat(parser.to_a)
    end
    res
  end

  def to_s
    res = [ @index ]
    @parsers.each do |parser|
      res.push(parser.to_s)
    end
    res.join(',')
  end
end
