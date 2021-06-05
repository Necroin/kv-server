## API
Method | Path | Body (json) | Description
--- | --- | --- | --- 
POST   | /kv      | ```{"key": "key_name", "value": object } ``` | Add a new record if key wasn't in the database
PUT    | /kv/{id} | ```{ "value": object } ``` | Update record if the key was in the database
GET    | /kv/{id} |  | Select record by key and return result
DELETE | /kv/{id} |  | Delete record if key was in the database
