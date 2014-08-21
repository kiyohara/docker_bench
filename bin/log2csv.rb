#!/usr/bin/env ruby

require_relative './lib/log_handler_command'
require_relative './lib/container_output_parser'

Class.new do
  include LogHandlerCommand

  def after_run
    @containers.each_with_index do |cont, i|
      if i == 0
        puts cont.header
      end
      puts cont.to_s
    end
  end
end.new().run
