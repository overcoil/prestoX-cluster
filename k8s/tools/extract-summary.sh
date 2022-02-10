#!/usr/bin/env bash
# 
# Extract summary of execution
#   Note PrestoDB and Trino use different tag for the planning time.
#   
#   PrestoDB: .queryStats.totalPlanningTime
#   Trino: .queryStats.planningTime
#
# The following jq expr will only emit 3 numbers ever.
#

jq -r '.query + "\n" + .state + " " + .queryStats.analysisTime +" " + .queryStats.planningTime + .queryStats.totalPlanningTime + " " + .queryStats.executionTime + "\n"' ${1}

