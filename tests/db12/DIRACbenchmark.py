#!/usr/bin/env python3

########################################################################
# File :    DIRACbenchmark.py
# Author :  Andrew McNab 
########################################################################

""" DIRAC Benchmark 2012 by Ricardo Graciani, and wrapper functions to
    run multiple instances in parallel by Andrew McNab.
    
    This file (DIRACbenchmark.py) is intended to be the ultimate upstream
    shared by different users of the DIRAC Benchmark 2012 (DB12). The
    canonical version can be found at https://github.com/?????

    This was adapted by Brian Bockelman for CMS and turned into a
    glideinWMS validation script.
"""

import os
import sys
import random
import urllib
import multiprocessing
import traceback

# Commenting out imports from glidein
#from export_siteconf_info import get_glidein_config, add_condor_config_var

version = '0.1 DB12'

def singleDiracBenchmark( iterations = 1 ):
  """ Get Normalized Power of one CPU in DIRAC Benchmark 2012 units (DB12)
  """

  # This number of iterations corresponds to 1kHS2k.seconds, i.e. 250 HS06 seconds

  n = int( 1000 * 1000 * 12.5 )
  calib = 250.0

  m = 0
  m2 = 0
  p = 0
  p2 = 0
  # Do one iteration extra to allow CPUs with variable speed (we ignore zeroth iteration)
  for i in range( iterations + 1 ):
    if i == 1:
      start = os.times()
    # Now the iterations
    for _j in range( n ):
      t = random.normalvariate( 10, 1 )
      m += t
      m2 += t * t
      p += t
      p2 += t * t

  end = os.times()
  cput = sum( end[:4] ) - sum( start[:4] )
  wall = end[4] - start[4]

  if not cput:
    return None
  
  # Return DIRAC-compatible values
  return { 'CPU' : cput, 'WALL' : wall, 'NORM' : calib * iterations / wall, 'UNIT' : 'DB12' }

def getCpuModel():
    with open("/proc/cpuinfo") as fp:
        for line in fp:
            if line.startswith("model name"):
                return line.split(":", 1)[-1].strip()
    return None

def singleDiracBenchmarkProcess( resultObject, iterations = 1 ):

  """ Run singleDiracBenchmark() in a multiprocessing friendly way
  """

  benchmarkResult = singleDiracBenchmark( iterations )
  
  if not benchmarkResult or 'NORM' not in benchmarkResult:
    return None
    
  # This makes it easy to use with multiprocessing.Process
  resultObject.value = benchmarkResult['NORM']

def multipleDiracBenchmark( instances = 1, iterations = 1 ):

  """ Run multiple instances of the DIRAC Benchmark in parallel  
  """

  processes = []
  results = []

  # Set up all the subprocesses
  for i in range( instances ):
    results.append( multiprocessing.Value('d', 0.0) )
    processes.append( multiprocessing.Process( target = singleDiracBenchmarkProcess, args = ( results[i], iterations ) ) )
 
  # Start them all off at the same time 
  for p in processes:  
    p.start()
    
  # Wait for them all to finish
  for p in processes:
    p.join()

  raw = [ result.value for result in results ]

  # Return the list of raw results, and the sum and mean of the list
  return { 'raw' : raw, 'sum' : sum(raw), 'mean' : sum(raw)/len(raw) }
  
def wholenodeDiracBenchmark( instances = None, iterations = 1 ): 

  """ Run as many instances as needed to occupy the whole machine
  """
  
  # Try $MACHINEFEATURES first if not given by caller
  if not instances and 'MACHINEFEATURES' in os.environ:
    try:
      instances = int( urllib2.urlopen( os.environ['MACHINEFEATURES'] + '/total_cpu' ).read() )
    except:
      pass

  # If not given by caller or $MACHINEFEATURES/total_cpu then just count CPUs
  if not instances:
    try:
      instances = multiprocessing.cpu_count()
    except:
      instances = 1
  
  return multipleDiracBenchmark( instances = instances, iterations = iterations )


def readAdValues(attrs, adname, castInt=False):
    """
    A very simple parser for the ads available at runtime.  Returns
    a dictionary containing
    - attrs: A list of string keys to look for.
    - adname: Which ad to parse; "job" for the $_CONDOR_JOB_AD or
      "machine" for $_CONDOR_MACHINE_AD
    - castInt: Set to True to force the values to be integer literals.
      Otherwise, this will return the values as a string representation
      of the ClassAd expression.
    Note this is not a ClassAd parser - will not handle new-style ads
    or any expressions.
    Will return a dictionary containing the key/value pairs that were
    present in the ad and parseable.
    On error, returns an empty dictionary.
    """
    retval = {}
    adfile = None
    if adname == 'job':
        adfile = os.environ.get("_CONDOR_JOB_AD")
    elif adname == 'machine':
        adfile = os.environ.get("_CONDOR_MACHINE_AD")
    else:
        print("Invalid ad name requested for parsing: %s" % adname)
        return retval
    if not adfile:
        print("%s adfile is not set in environment." % adname)
        return retval
    attrs = [i.lower() for i in attrs]

    try:
        with open(adfile) as fd:
            for line in fd:
                info = line.strip().split("=", 1)
                if len(info) != 2:
                    continue
                attr = info[0].strip().lower()
                if attr in attrs:
                    val = info[1].strip()
                    if castInt:
                        try:
                            retval[attr] = int(val)
                        except ValueError:
                            print("Error parsing %s's %s value: %s", (adname, attr, val))
                    else:
                        retval[attr] = val
    except IOError:
        print("Error opening %s ad:" % adname)
        print(traceback.format_exc())
        return {}

    return retval

def jobslotDiracBenchmark( instances = None, iterations = 1 ):

  """ Run as many instances as needed to occupy the job slot
  """

  if not instances:
      adValues = readAdValues(['cpus'], 'machine', castInt=True)
      instances = adValues.setdefault('cpus', 1)
  
  return multipleDiracBenchmark( instances = instances, iterations = iterations )


def main():

#    Commenting out the part that tries to read from the glidein config
#
#    try:
#        glidein_config = get_glidein_config()
#    except:
#        glidein_config = {'GLIDEIN_CPUS': 0}
#
#    try:
#        model = getCpuModel()
#    except:
#        print "Failed to lookup CPU model"
#        traceback.print_exc()
#        model = None
#
#    try:
#        cpus = int(glidein_config['GLIDEIN_CPUS'])
#    except:
#        cpus = None

    # set number of cpus
    cpus = int(sys.argv[1])

    result = jobslotDiracBenchmark(instances=cpus)['sum']

    print("Result from DIRAC benchmark: %.2f" % result)
    print("DIRAC per core: %.2f" % (result / cpus))

#    if model:
#        print "Detected CPU model '%s'" % model
#
#    if not glidein_config or not cpus:
#        return

#    if 'mean' in result:
#        add_condor_config_var(glidein_config, name="DIRACBenchmark", kind="C", value=str(result['mean']))
#    add_condor_config_var(glidein_config, name="CpuModelName", kind="S", value='"'+model.replace(" ", "_")+'"')
#
#
# If we run as a command
#   
if __name__ == "__main__":

  try:
    main()
  except:
    # Always succeed - this is advisory info.
    traceback.print_exc()
    sys.exit(0)
