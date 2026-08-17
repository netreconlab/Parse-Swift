// main.js (on your Parse Server)
Parse.Cloud.job("myBackgroundJob", async(request) => {
  console.log('Job started with params: ' + JSON.stringify(request.params));
  
  // Perform long-running operations
  // For example: data migrations, cleanup, batch processing
  // Access batch size from params: request.params.batchSize || 50
  
  // Your job logic here
  // ...
  
  return "Job completed successfully";
});
