#!/usr/bin/env ruby

require_relative './lib/log_handler_command'
require_relative './lib/container_output_parser'
require 'sqlite3'

Class.new do
  include LogHandlerCommand

  SQLITE_TABLE_NAME = 'containers'

  def parse_settings
    super.concat([
      ["-d", "--db [PATH]", "Output db file path"],
    ])
  end

  def require_opts
    super.concat([
      "db"
    ])
  end

  def opt_db_file
    @option['db']
  end

  def before_run
    super

    if File.exist?(opt_db_file)
      fail "Output db file #{opt_db_file} already exists"
    end

    cop = ContainerOutputParser.new

    @db = SQLite3::Database.new(opt_db_file)
    @db.execute "create table #{SQLITE_TABLE_NAME} (#{cop.sqlite_table_defines.join(',')});"
  end

  def after_run
    super
    @containers.each do |cont|
      @db.execute "insert into #{SQLITE_TABLE_NAME} values ( #{cont.sqlite_insert_defines.join(',')} );", cont.to_a
    end
  end
end.new().run
