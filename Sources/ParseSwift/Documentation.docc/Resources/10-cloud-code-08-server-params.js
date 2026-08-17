// main.js (on your Parse Server)
Parse.Cloud.define("testCloudCode", async(request) => {
  console.log('From client: ' + JSON.stringify(request));
  
  // Access the argument1 parameter
  const argument1 = request.params.argument1;
  
  // Return the parameter value back to the client
  return argument1;
});
