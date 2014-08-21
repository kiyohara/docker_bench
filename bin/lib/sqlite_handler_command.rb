require_relative 'common_command'
require_relative 'container_output_parser'
require 'sqlite3'

module SqliteHandlerCommand
  include CommonCommand

  def parse_settings
    super.concat([
      ["-d", "--db [PATH]", "DB file path"],
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

    unless File.exist?(opt_db_file)
      fail "Output db file #{opt_db_file} not found"
    end
    @db = SQLite3::Database.new(opt_db_file)

    @containers = []
  end

  def initial_data
    @db.execute('select * from containers where container_num = 0 limit 1')[0]
  end

  def bench_data
    @db.execute('select * from containers where container_num > 0 order by container_num')
  end
end
