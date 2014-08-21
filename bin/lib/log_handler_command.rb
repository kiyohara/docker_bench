require_relative 'common_command'
require_relative 'container_output_parser'

module LogHandlerCommand
  include CommonCommand

  def parse_settings
    super.concat([
      ["-l", "--log [PATH]", "Log file path"],
    ])
  end

  def require_opts
    super.concat([
      "log"
    ])
  end

  def opt_log_file
    @option['log']
  end

  def before_run
    super

    @log_file = open(opt_log_file)
    @containers = []
  end

  def main
    index = -1
    cont_parser = nil
    @log_file.each do |line|
      if line =~ / =====>$/
        index += 1
        cont_parser = ContainerOutputParser.new(index)
      elsif line =~ / =====<$/
        @containers.push(cont_parser)
        cont_parser = nil
      end

      cont_parser.parse(line) if cont_parser
    end
  end
end
