Lobster
=======

Simple job service that was originally written to run hadoop jobs, but can be 
used for any batch-processing scripts that you want to run.

Alpha Version Warning
---------------------

Lobster has not been fully released and tested yet.

How It Works
------------

### Create a `config/schedule.rb` file

~~~~~ ruby
job "my-job" do
  cmd "runthis && runthat >> log/here.log"
  delay 5 # minutes
end
~~~~~

### Run Lobster

- In the console with `LOBSTER_DIR=/path/to/jobs/directory sudo lobster run`
- As a service with `LOBSTER_DIR=/path/to/jobs/directory sudo lobster start`

The job `my-job` will start in the next 5 minutes, and once it's done, 
lobster will wait 5 minutes before starting it again.

Any log in stderr/stdout will be written in `$LOBSTER_DIR/log/lobster.output` 
along with some other useful information for monitoring.

The current directory where the job command is run is `$LOBSTER_DIR`.

How To Install
--------------

    gem install lobster --pre


