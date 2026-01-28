// Cloud Code example (main.js on Parse Server)

Parse.Cloud.define("sendWelcomeNotification", async (request) => {
  // This code runs securely on the server with access to the primary key
  
  const Installation = Parse.Object.extend("Installation");
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
