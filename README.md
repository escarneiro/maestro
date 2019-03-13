# maestro
Simple script that executes batch commands in a pool of selected devices (like a simple ansible)

It is based on shell script and tcl's expect interpreter.
Features parallel execution.

Usage:
 maestro.sh [-t <num_threads>] <hosts file> <commands file>
  Where:
   -t <int>         How many parallel threads to run
   hosts file       File containg the hostnames/ip adresses on which to execute the commands
   commands file    The commands to be executed on the hosts
