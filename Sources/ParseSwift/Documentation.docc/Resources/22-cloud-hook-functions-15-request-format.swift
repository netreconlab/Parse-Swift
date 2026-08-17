/*
 When Parse Server calls your webhook, it sends a POST request:
 
 POST https://api.example.com/foo
 Headers:
   X-Parse-Application-Id: your-app-id
   X-Parse-REST-API-Key: your-rest-key (if configured)
   Content-Type: application/json
 
 Body:
 {
   "params": {
     "argument1": "value1",
     "argument2": "value2"
   },
   "user": {
     "objectId": "user123",
     "sessionToken": "r:abc123..."
   }
 }
 
 The params field contains the arguments passed to the function.
 The user field contains information about the authenticated user.
 */
