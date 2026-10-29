#!/bin/bash
#@ description: SQLite command-line shell runs a query
#@ param sqlite = sqlite
#@ modules: ${sqlite}
#@ ntasks: 1
#@ time: 5
#@ tags: lang quick

echo "SELECT 1+1;" | sqlite3 test.db
