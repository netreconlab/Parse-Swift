// Example webhook endpoint receiving trigger data (Node.js/Express)
app.post('/afterSave', (req, res) => {
    const { object, original } = req.body;
    
    // Process the trigger event
    console.log('Object saved:', object);
    console.log('Original values:', original);
    
    // Return success response
    res.json({ success: true });
});
