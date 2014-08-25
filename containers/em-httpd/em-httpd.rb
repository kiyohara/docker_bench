#!/usr/bin/env ruby
require 'optparse'
require 'eventmachine'
require 'em-http-server'
require 'json'
require 'awesome_print'

DEFAULT_LISTEN_PORT = 8888
COLOR=false

STDOUT.sync = true

AwesomePrint.defaults = {
  indent: -4,
}

class CallbackReceiver < EM::HttpServer::Server

  def process_http_request
    begin
      recv_data = JSON.parse(@http_content)
      if COLOR
        puts "* Callback recv :".green
        ap recv_data
      else
        puts recv_data
      end
      puts
    rescue => e
      if COLOR
        puts e.message.red
      else
        puts e.message
      end
      puts @http_content
    end

    response = EM::DelegatedHttpResponse.new(self)
    response.status = 200
    response.content_type 'text/html'
    response.content = 'CallbackReceiver recv data successfully\n'
    response.send_response
  end

  def http_request_errback e
    # printing the whole exception
    puts e.inspect
  end

end

Class.new do
  def opt_parse
    @option = OptionParser.new do |opts|
      opts.on "-p", "--port [PORT]", "listen port number"
    end.getopts

    @port = @option['port'] || DEFAULT_LISTEN_PORT
  end

  def run
    opt_parse

    ['INT','TERM'].each do |s|
      Signal.trap(s) { EM.stop }
    end

    EM::run do
      EM::start_server("0.0.0.0", @port, CallbackReceiver)
      if COLOR
        puts "wait callback...".cyan
      else
        puts "wait callback..."
      end
      puts
    end
  end
end.new.run

