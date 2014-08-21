#!/usr/bin/env ruby

require_relative './lib/sqlite_handler_command'

Class.new do
  include SqliteHandlerCommand

  def parse_settings
    super.concat([
      ["--filter [[col_name],col_name...]", "filter col names"],
      ["--no-header",                       "output no header"],
    ])
  end

  def opt_filters
    @option['filter'] ? @option['filter'].split(',') : []
  end

  def opt_header
    @option['no-header'].nil? ? true : false
  end

  def main
    init_data = ContainerOutputParser.new.from_a(initial_data)
    prev_data = crr_data = nil

    bench_data.each_with_index do |i, index|
      crr_data = ContainerOutputParser.new.from_a(i)

      crr_data.calc_delta!(init_data, prev_data)

      if opt_filters.size > 0
        if index == 0 && opt_header
          puts opt_filters.join(',')
        end
        arr_out = []
        opt_filters.each do |filter|
          filtered = crr_data.to_hash[filter] || ''
          arr_out.push(filtered)
        end
        puts arr_out.join(',')
      else
        if index == 0 && opt_header
          puts crr_data.headers.join(',')
        end
        puts crr_data
      end

      prev_data = crr_data
    end
  end
end.new().run
