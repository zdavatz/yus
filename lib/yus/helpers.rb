#!/usr/bin/env ruby
# AutoInvoicer -- ydim -- 13.01.2006 -- hwyss@ywesee.com

require 'rclconf'
require 'getoptlong'
require 'highline/import'

module YUS
  def self.default_opts
    opts = []
    GetoptLong.new(
      ['--help', '-h', GetoptLong::NO_ARGUMENT],
      ['--config', '-c', GetoptLong::OPTIONAL_ARGUMENT],
      ['--root_name', '-r', GetoptLong::OPTIONAL_ARGUMENT],
      ['--server_url', '-u', GetoptLong::OPTIONAL_ARGUMENT],
      ['--yus_dir', '-d', GetoptLong::OPTIONAL_ARGUMENT]
    ).each { |key, pair|
      opts.push("#{key}=#{pair}")
    }
    opts
  end

  def self.session(opts = self.default_opts)
    if /--help=/.match(opts[0])
            puts <<-EOF
#{File.basename(__FILE__)} ...

-h, --help:
   show help

-c -config
   config directory of yus.yml

-r --root_name
   Root name to use for reading yus

-s --config
   path to YAML-config of YUS
      EOF
      exit
    end
    default_dir = File.join(ENV['HOME'], '.yus')
    default_config_files = [
      File.join(default_dir, 'yus.yml'),
      '/etc/yus/yus.yml',
    ]
     defaults = {
      'config'            => default_config_files,
      'root_name'         => 'admin',
      'server_url'        => 'drbssl://localhost:9997',
      'yus_dir'           => default_config_files,
    }

    config = RCLConf::RCLConf.new(opts, defaults)
    config.load(config.config)

    server = DRb::DRbObject.new(nil, config.server_url)
    server.ping

    session = nil
    begin
      pass = YUS.get_password("Password for #{config.root_name}: ")
      session = server.login(config.root_name, pass.to_s, 'commandline')
    rescue Yus::YusError => e
      puts e.message
      retry
    end
    return session
  end
  def self.get_password(prompt='Password: ')
    ask(prompt) { |q| q.echo = false}
  end
end
