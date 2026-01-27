// main.js (on your Parse Server)
Parse.Cloud.beforeSave("GameScore", async(request) => {
  // Access the context data sent from the client
  console.log('From client context: ' + JSON.stringify(request.context));
  
  // You can use context to implement conditional logic
  if (request.context && request.context.hello === "world") {
    console.log("Context matched expected value");
    // Perform special validation or operations
  }
  
  // Context is not stored with the object - it's only available in hooks
});
