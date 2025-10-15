const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();

// Send notification when new order is created
exports.sendNewOrderNotification = functions.firestore
  .document('orders/{orderId}')
  .onCreate(async (snap, context) => {
    const orderData = snap.data();
    const orderId = context.params.orderId;

    // Get all admin tokens
    const adminTokensSnapshot = await admin.firestore()
      .collection('admin_tokens')
      .get();

    const tokens = adminTokensSnapshot.docs.map(doc => doc.data().token);

    if (tokens.length === 0) {
      console.log('No admin tokens found');
      return;
    }

    const message = {
      notification: {
        title: '🔔 New Order Received!',
        body: `Order from ${orderData.userName} - ₦${orderData.total.toFixed(0)}`,
      },
      data: {
        orderId: orderId,
        type: 'new_order',
        click_action: 'FLUTTER_NOTIFICATION_CLICK',
      },
    };

    // Send to all admin devices
    try {
      const response = await admin.messaging().sendMulticast({
        tokens: tokens,
        ...message,
      });
      console.log('Successfully sent to admins:', response.successCount);
    } catch (error) {
      console.error('Error sending to admins:', error);
    }
  });

// Send notification when order status changes
exports.sendOrderStatusUpdate = functions.firestore
  .document('orders/{orderId}')
  .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after = change.after.data();
    const orderId = context.params.orderId;

    // Only send if status changed
    if (before.status === after.status) {
      return;
    }

    const userId = after.userId;

    // Get user's device token
    const userTokenDoc = await admin.firestore()
      .collection('user_tokens')
      .doc(userId)
      .get();

    if (!userTokenDoc.exists) {
      console.log('No token found for user:', userId);
      return;
    }

    const token = userTokenDoc.data().token;

    let title = '';
    let body = '';

    switch (after.status) {
      case 'preparing':
        title = '👨‍🍳 Order is Being Prepared!';
        body = 'Your delicious meal is being cooked with care.';
        break;
      case 'on_the_way':
        title = '🚗 Order is On the Way!';
        body = 'Your food is heading to you. Get ready!';
        break;
      case 'delivered':
        title = '✅ Order Delivered!';
        body = 'Your order has been delivered. Enjoy your meal!';
        break;
      case 'cancelled':
        title = '❌ Order Cancelled';
        body = 'Your order has been cancelled.';
        break;
      default:
        return;
    }

    const message = {
      notification: {
        title: title,
        body: body,
      },
      data: {
        orderId: orderId,
        status: after.status,
        type: 'order_status',
        click_action: 'FLUTTER_NOTIFICATION_CLICK',
      },
      token: token,
    };

    try {
      await admin.messaging().send(message);
      console.log('Status update sent to user:', userId);
    } catch (error) {
      console.error('Error sending status update:', error);
    }
  });

// Send notification when special offer is created
exports.sendSpecialOfferNotification = functions.firestore
  .document('special_offers/{offerId}')
  .onCreate(async (snap, context) => {
    const offerData = snap.data();

    // Only send if offer is active
    if (!offerData.isActive) {
      return;
    }

    // Get all user tokens
    const userTokensSnapshot = await admin.firestore()
      .collection('user_tokens')
      .get();

    const tokens = userTokensSnapshot.docs.map(doc => doc.data().token);

    if (tokens.length === 0) {
      console.log('No user tokens found');
      return;
    }

    const message = {
      notification: {
        title: `🎉 ${offerData.title}`,
        body: offerData.description || 'Check out our special offer!',
      },
      data: {
        offerId: context.params.offerId,
        type: 'special_offer',
        discount: offerData.discount || '',
        click_action: 'FLUTTER_NOTIFICATION_CLICK',
      },
    };

    // Send in batches of 500 (FCM limit)
    const batchSize = 500;
    for (let i = 0; i < tokens.length; i += batchSize) {
      const batch = tokens.slice(i, i + batchSize);
      
      try {
        const response = await admin.messaging().sendMulticast({
          tokens: batch,
          ...message,
        });
        console.log(`Batch ${i / batchSize + 1} sent: ${response.successCount} successful`);
      } catch (error) {
        console.error('Error sending batch:', error);
      }
    }
  });

// Clean up old notifications (runs daily)
exports.cleanupOldNotifications = functions.pubsub
  .schedule('every 24 hours')
  .onRun(async (context) => {
    const thirtyDaysAgo = new Date();
    thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);

    const oldNotifications = await admin.firestore()
      .collection('notifications')
      .where('createdAt', '<', thirtyDaysAgo)
      .get();

    const batch = admin.firestore().batch();
    oldNotifications.docs.forEach(doc => {
      batch.delete(doc.ref);
    });

    await batch.commit();
    console.log(`Deleted ${oldNotifications.size} old notifications`);
  });