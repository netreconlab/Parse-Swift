// main.js (on your Parse Server)
Parse.Cloud.define("testCloudCodeError", async(request) => {
  console.log('From client: ' + JSON.stringify(request));
  
  // Throw a custom Parse Error with code 3000
  throw new Parse.Error(3000, "cloud has an error on purpose.");
});
