#!/usr/bin/env python
from pymongo import MongoClient

client = MongoClient(
    host = '54.236.34.143:27017'
)
db = client["YoMamasDatabase"]
col = db["IsSoPhat"]

PhatMomma = {"Name": "RosieODonnell"}

col.insert_one(PhatMomma)

database_names = client.list_database_names()
print ("databases:",database_names)
print "-------------------"
#print dir(col)

