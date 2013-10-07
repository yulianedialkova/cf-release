#!/var/vcap/packages/ruby/bin/ruby --disable-all

require "logger"
require "fileutils"
require "json"

FileUtils.mkdir_p("/var/vcap/sys/log/dea_next")
logger = Logger.new("/var/vcap/sys/log/dea_next/drain.log")

job_change, hash_change, *updated_packages = ARGV

logger.info("Drain script invoked with #{ARGV.join(" ")}")

dea_pidfile = "/var/vcap/sys/run/dea_next/dea_next.pid"
warden_pidfile = "/var/vcap/sys/run/warden/warden.pid"
snapshot_path = "/var/vcap/data/dea_next/db/instances.json"

if !File.exists?(dea_pidfile)
  logger.info("DEA not running")
  puts 0
  exit 0
end

if !File.exists?(warden_pidfile)
  logger.info("Warden not running")
  puts 0
  exit 0
end

begin
  dea_pid = File.read(dea_pidfile).to_i
  warden_pid = File.read(warden_pidfile).to_i

  staging_tasks = File.exists?(snapshot_path) ? JSON.load(File.open(snapshot_path))["staging_tasks"] : []

  if staging_tasks.empty?
    logger.info("Sending signal USR2 to Warden.")
    Process.kill("USR2", warden_pid)

    logger.info("Sending signal KILL to DEA.")
    Process.kill("KILL", dea_pid)

    timeout = 0
  else
    logger.info("Sending signal USR1 to DEA to trigger shutdown message.")
    Process.kill("USR1", dea_pid)

    timeout = -10
  end

  logger.info("Setting timeout as #{timeout}.")
  puts timeout
rescue Errno::ESRCH => e
  logger.info("Caught exception: #{e}")
  puts 0
end
