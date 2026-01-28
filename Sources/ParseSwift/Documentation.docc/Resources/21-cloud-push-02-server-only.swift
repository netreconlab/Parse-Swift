/*
 WARNING: Primary key usage is server-side only
 
 The push-sending examples in this tutorial require the use of the Parse primary key
 and must ONLY run in a trusted server-side environment.
 
 Never include your primary key in client applications. Installation management and
 channel subscriptions (for example, via Installation.current().save()) happen in
 your client apps without using the primary key.
 */

// This Swift example shows how to send pushes from a trusted server-side environment
// (for example, Parse-Server-Swift/Vapor), and should not be run inside your client app.
// Parse Cloud Code itself is implemented in JavaScript (e.g., main.js) and would use a
// different, JavaScript-based implementation for server-side push logic.
