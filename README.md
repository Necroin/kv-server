## API
Path | Method | Body (json) | Description
--- | --- | --- | --- 
/kv | POST | ```{"key": "key_name", "value": object } ``` | Add a new record if key wasn't in the database
/kv/:key | PUT | ```{ "value": object } ``` | Update record if the key was in the database
/kv/:key | GET |  | Select record by key and return result
/kv/:key | DELETE | | Delete record if key was in the database
