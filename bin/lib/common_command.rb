# here = File.dirname(__FILE__)
# $LOAD_PATH << File.expand_path(File.join(here, '..', 'lib'))

require 'optparse'
require 'yaml'
require 'awesome_print'

AwesomePrint.defaults = {
  indent: -4,
}

module CommonCommand
  def parse_settings
    [
      ["-f", "--config [PATH]", "Config file path"],
      ["--debug [LEVEL]", "Show debug info"],
    ]
  end

  def require_opts
    []
  end

  def opt_parse
    @option = OptionParser.new do |opts|
      parse_settings.each do |opt_set|
        opts.on(*opt_set)
      end
    end.getopts

    require_opts.each do |opts|
      if @option[opts].nil?
        raise "option --#{opts} required"
      end
    end
  end

  def opt_debug
    @option ? @option['debug'].to_i : 0
  end
  def opt_debug?
    opt_debug > 0
  end

  def load_config
    @config = {}

    config_path = @option['config']
    if config_path && File.exist?(config_path)
      @config.merge!(YAML.load_file(config_path))
    else
      raise "No such config : #{@option['config']}" if @option['config']
    end
  end

  def before_run
    opt_parse
    load_config
  end

  def main
    raise "#{self.class}::#{__method__} not implemented"
  end

  def after_run
  end

  def run
    before_run
    main
    after_run
  rescue => e
    puts e.message.red
    puts e.backtrace.join("\n") if opt_debug?
    exit 1
  end
end
