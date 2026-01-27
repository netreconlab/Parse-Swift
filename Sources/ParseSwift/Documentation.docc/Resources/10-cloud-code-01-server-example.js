// main.js (on your Parse Server)
Parse.Cloud.define('hello', async (request) => {
  console.log('From client: ' + JSON.stringify(request));
  return 'Hello world!';
});
