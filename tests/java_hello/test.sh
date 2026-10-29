#!/bin/bash
#@ description: Java: javac + java; the JVM sees the job's CPU and memory limits
#@ param java = openjdk
#@ modules: ${java}
#@ ntasks: 1
#@ cpus-per-task: 2
#@ mem: 2G
#@ time: 5
#@ tags: lang

javac Hello.java
java -cp . Hello
