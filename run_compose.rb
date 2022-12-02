#!/usr/bin/env ruby

require 'yaml'
require 'shellwords'
require 'fileutils'
require 'digest'

require 'subprocess'

class ComposeRunner
  attr_reader :config

  def initialize
    load_config    
  end

  def run!
    run_pre_start_scripts
    copy_configs
    create_env_file
    calculate_configs_sha
    run_compose
  end

  def load_config
    hosts_config = YAML.load_file("/app/hosts.yml")
  
    defaults = hosts_config["defaults"]
    host = hosts_config["hosts"][ENV['HOSTNAME']]

    @config = {}

    (defaults.keys + hosts.keys).uniq.each do |key|
      default_val = defaults[key]
      host_val = host[key]

      if default_val && host_val
        if default_val.class != host_val.class
          raise ArgumentError.new("key #{key} not the same type in defaults and host")
        end
        
        if host_val.is_a?(Array)
          @config[key] = default_val + host_val
        elsif host_val.is_a?(Hash)
          @config[key] = default_val.merge(host_val)
        else
          @config[key] = host_val
        end
      else
        @config[key] = [default_val, host_val].compact.first
      end
    end
  end

  def run_pre_start_scripts
    config["pre-start"].each do |script|
      Subprocess.check_call("scripts/#{script}")
    rescue Subprocess::NonZeroExit
      # this is fine
    end
  end

  def copy_configs
    config["configs"].each do |c|
      FileUtils.cp_r("/app/#{c}", "/configs", preserve: true)
    end
  end

  def create_env_file
    File.open("/app/.env", "w+") do |f|
      f.puts("__DOCKERSTACK_ENV=1")

      config["environment"].each do |env|
        f.puts(env)
      end
    end
  end

  def calculate_configs_sha
    tar = Subprocess.check_output(['tar', '--sort=name', '--owner=root:0', '--group=root:0', '--mtime="UTC 2022-01-01"', '-C', '/', '-cf', '-', '/configs', '/app/.env'])
    
    ENV['CONFIGS_SHA'] = Digest::SHA256.hexdigest(tar)
  end

  def stack_filenames
    config["stacks"].map { |s| "stacks/#{s}.yml" }
  end

  def base_compose
    "/usr/bin/docker-compose --ansi never -f docker-compose.yml " + stack_filenames.map { |f| "-f #{f}" }.join(" ")
  end

  def start_crons
    scheduler = Rufus::Scheduler.new
    config["crons"].each do |cron|
      script = cron["script"]

      if cron["service"]
        script = %Q{#{base_docker_compose} run --rm -T "#{cron["service"]}"}
      end

      if !script.nil?
        scheduler.cron(cron['schedule']) do
          Subprocess.check_call(Shellwords.split(script))
        rescue Subprocess::NonZeroExit
          # this is fine
        end
      end
    end

    scheduler.join
  end

  def run_compose
    if ARGV[0].nil?
      Subprocess.check_call(Shellwords.split("#{base_docker_compose} up --no-color --remove-orphans --quiet-pull --detach"))
      start_crons
    else
      exec("#{base_docker_compose} #{ARGV.shelljoin}")
    end
  end
end

if $PROGRAM_NAME == __FILE__
  ComposeRunner.new.run!
end
