const { Firestore } = require('@google-cloud/firestore');

const firestore = new Firestore();

exports.deliveryFn = async (event) => {

  const message = event.data
    ? JSON.parse(
        Buffer.from(event.data, 'base64').toString()
      )
    : null;

  if (!message) {
    console.log("No message");
    return;
  }

  const orderId = message.orderId;

  console.log("Delivering order:", orderId);

  await firestore
    .collection("orders")
    .doc(orderId)
    .update({ status: "DELIVERED" });

  console.log("Order delivered:", orderId);
};

