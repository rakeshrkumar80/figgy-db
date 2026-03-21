const express = require('express');
const { Firestore } = require('@google-cloud/firestore');
const { PubSub } = require('@google-cloud/pubsub');

const app = express();
app.use(express.json());

const firestore = new Firestore();
const pubsub = new PubSub();

app.post('/order', async (req, res) => {

  const orderId = Date.now().toString();

  const order = {
    orderId,
    userId: req.body.userId,
    supplierId: req.body.supplierId,
    status: "CREATED",
    createdAt: new Date()
  };

  await firestore.collection('orders').doc(orderId).set(order);

  await pubsub.topic('order-created').publishMessage({
    data: Buffer.from(JSON.stringify(order))
  });

  res.send(order);
});

app.listen(8080, () => {
  console.log("Server started");
});