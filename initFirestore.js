const { Firestore } = require('@google-cloud/firestore');

const firestore = new Firestore({
  projectId: process.env.GOOGLE_CLOUD_PROJECT,
});

async function init() {

  console.log("Creating users");

  await firestore.collection('users').doc('user1').set({
    name: 'John',
    phone: '111111',
    address: 'US',
    createdAt: new Date()
  });

  console.log("Creating suppliers");

  await firestore.collection('suppliers').doc('sup1').set({
    name: 'BurgerShop',
    city: 'Chicago',
    status: 'OPEN',
    rating: 5
  });

  console.log("Creating menus");

  await firestore.collection('menus').doc('menu1').set({
    supplierId: 'sup1',
    itemName: 'Burger',
    price: 10,
    available: true
  });

  console.log("Creating orders");

  await firestore.collection('orders').doc('order1').set({
    userId: 'user1',
    supplierId: 'sup1',
    status: 'CREATED',
    amount: 10,
    createdAt: new Date()
  });

  console.log("Creating deliveryAgents");

  await firestore.collection('deliveryAgents').doc('agent1').set({
    name: 'Mike',
    status: 'AVAILABLE',
    city: 'Chicago'
  });

  console.log("DONE");
}

init();