Lobster
=======

Simple job service that was originally written to run hadoop jobs, but can be 
used for any batch-processing scripts that you want to run.

Lobster runs as a service (daemon) and regularly checks a schedule in 
`$LOBSTER_DIR/config/schedule.rb`. The goal is to run the scheduled jobs in 
parallel but a job can't run twice at the same time (no overlap). The only 
configuration needed is the delay between 2 job runs.

How It Works
------------

### Create a `config/schedule.rb` file

~~~~~ ruby
# config/schedule.rb (this is the default schedule location)
job "my-job" do
  cmd "runthis && runthat >> log/here.log"
  delay 5 # minutes
end
~~~~~

### Run Lobster

Two environment variables are used (with defaults):
- `LOBSTER_DIR` is the directory used for all job commands, and where the 
  configuration/schedule files are (default: current 
  directory)
- `LOBSTER_ENV` is a variable used to handle different environments (default: 
  development)

You need write permission to `/var/run/lobster/` for pids, this path is 
configurable.

- `lobster run` will run in the console
- or `lobster start` as a deamon

### Configuration

The lobster configuration file should be located in 
`$LOBSTER_DIR/config/lobster.yml` and has the following layout

~~~~ yaml
# default values

# monitor the daemon and restart it if it stops
monitor: true
# log directory, absolute or relative to the LOBSTER_DIR
log_dir: log
# pids directory, absolute or relative to the LOBSTER_DIR
pid_dir: /var/run/lobster/
# schedule file, absolute or relative to the LOBSTER_DIR
schedule_file: config/schedule.rb

# environment overrides, the env variable LOBSTER_ENV has 
# to be set (default: development)
my_test_env:
  monitor: false
  log_dir: test_los
my_prod_env:
  pid_dir: /var/run/
~~~~

Any log in stderr/stdout will be written in the log directory as 
`lobster.output`, the actual lobster log is in `lobster.log`

How To Install
--------------

    gem install lobster

Capistrano Deployment
=====================

It is very easy to have a lobster project with a proper `config/lobster.yml` to 
handle different environments such as development, testing and production. You 
can simply have a `schedule.rb`file per environment.

Then you can use capistrano to deploy the new jobs and schedule to your servers 
(the schedule is automatically reloaded).
