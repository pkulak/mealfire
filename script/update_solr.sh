#!/usr/bin/env bash
wget http://localhost:8080/solr/dataimport?command=full-import\&clean=false -O mealfire/log/dataimport.log