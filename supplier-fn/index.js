const { Firestore } = require("@google-cloud/firestore");
const { PubSub } = require("@google-cloud/pubsub");

const firestore = new Firestore();
const pubsub = new PubSub();

exports.supplierFn = async (cloudEvent) => {

  try {

    const data = JSON.parse(
      Buffer.from(cloudEvent.data, "base64").toString()
    );

    const orderId = data.orderId;

    console.log("Processing order:", orderId);

    // always accept
    const status = "ACCEPTED";

    await firestore
      .collection("orders")
      .doc(orderId)
      .update({ status });

    await pubsub
      .topic("order-accepted")
      .publishMessage({
        data: Buffer.from(
          JSON.stringify({ orderId })
        )
      });

    console.log("Updated:", status);

  } catch (err) {

    console.error(err);

  }

};