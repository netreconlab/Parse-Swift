// Cloud Code example (main.js on Parse Server)

Parse.Cloud.define("sendWelcomeNotification", async (request) => {
  // This code runs securely on the server with access to the primary key
  
  // Ensure the request is authenticated before accessing request.user.id
  if (!request.user) {
    throw new Parse.Error(Parse.Error.SESSION_MISSING, "User must be authenticated to send a welcome notification.");
  }
  
  const Installation = Parse.Installation;
  const query = new Parse.Query(Installation);
  query.equalTo("userId", request.user.id);
  
  const push = await Parse.Push.send({
    where: query,
    data: {
      alert: "Welcome to our app!"
    }
  }, { useMasterKey: true });
  
  return { success: true, pushId: push };
});
