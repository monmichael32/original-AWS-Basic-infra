from pymongo import MongoClient
from pymongo.errors import ConnectionFailure
client = MongoClient ("3.236.202.254")
try:
   # The ismaster command is cheap and does not require auth.
   client.admin.command('ismaster')
except ConnectionFailure:
   print("Server not available")

mydatabase = client.mongodb_one
students = [ {'name': 'Audi', 'price': 52642},
    {'name': 'Mercedes', 'price': 57127},
    {'name': 'Skoda', 'price': 9000},
    {'name': 'Volvo', 'price': 29000},
    {'name': 'Bentley', 'price': 350000},
    {'name': 'Citroen', 'price': 21000},
    {'name': 'Hummer', 'price': 41400},
    {'name': 'Volkswagen', 'price': 21600} ]
mydatabase = client.test
mydatabase.students.insert_many(students)
#mydatabase.collection_names()   
#mydatabase.list_collection_names()
collections = mydatabase.list_collection_names()
print(collections)
#print(mydatbase.collectionnames())
#client.create_collection("Names") 
~                                   
