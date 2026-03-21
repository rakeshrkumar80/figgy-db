const { Firestore } = require('@google-cloud/firestore');
const { PubSub } = require('@google-cloud/pubsub');

const firestore = new Firestore();
const pubsub = new PubSub();

exports.supplierFn = async (message) => {

  const data = JSON.parse(
    Buffer.from(message.data, 'base64').toString()
  );

  const orderId = data.orderId;

  console.log("Processing order:", orderId);

  // simulate supplier decision
  const accepted = Math.random() > 0.5;

  const status = accepted ? "ACCEPTED" : "REJECTED";

  await firestore
    .collection("orders")
    .doc(orderId)
    .update({ status });

  const topic = accepted
    ? "order-accepted"
    : "order-rejected";

  await pubsub.topic(topic).publishMessage({
    data: Buffer.from(
      JSON.stringify({ orderId })
    )
  });

  console.log("Order updated:", status);
};