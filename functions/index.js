// The Cloud Functions for Firebase SDK to create Cloud Functions and setup triggers.
const functions = require('firebase-functions');

// The Firebase Admin SDK to access Cloud Firestore.
const admin = require('firebase-admin');
admin.initializeApp();
// // Create and Deploy Your First Cloud Functions
// // https://firebase.google.com/docs/functions/write-firebase-functions
//
// exports.helloWorld = functions.https.onRequest((request, response) => {
//   functions.logger.info("Hello logs!", {structuredData: true});
//   response.send("Hello from Firebase!");
// });
exports.sendPushNotification = functions.firestore.document('/burgerOrders/{orderId}').onCreate((snap, context) => {
  var values = snap.data();

  var payload = {
    notification: {
      title: 'An Order Has Been Made',
      body: 'Order Number: '+values.orderNo+'\nby: '+values.name +'\nat :'+values.time
      }    
  }   
  
  return admin.messaging().sendToTopic('burgerOrders', payload);
});
