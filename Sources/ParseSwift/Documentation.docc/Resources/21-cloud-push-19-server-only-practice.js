// Cloud Code example (main.js on Parse Server)

Parse.Cloud.define("sendWelcomeNotification", async (request) => {
  // This code runs securely on the server with access to privileged credentials (master key)
  
  // Ensure the request is authenticated before accessing request.user
  if (!request.user) {
    throw new Parse.Error(Parse.Error.SESSION_MISSING, "User must be authenticated to send a welcome notification.");
  }
  
  const Installation = Parse.Installation;
  const query = new Parse.Query(Installation);
  // Assumes each Installation has a `user` pointer column pointing to the owning user
  query.equalTo("user", request.user);
  
  const pushResult = await Parse.Push.send({
    where: query,
    data: {
      alert: "Welcome to our app!"
    }
  }, { useMasterKey: true });
  
  return { success: true, pushResult };
});
