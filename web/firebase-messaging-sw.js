importScripts('/firebase-config.js');
importScripts('https://www.gstatic.com/firebasejs/11.6.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/11.6.0/firebase-messaging-compat.js');

firebase.initializeApp(self.FIREBASE_WEB_CONFIG);
const messaging = firebase.messaging();

messaging.onBackgroundMessage(function (payload) {
  const title = payload.notification?.title || payload.data?.title || 'PetFolio';
  const options = {
    body: payload.notification?.body || payload.data?.body || '',
    data: payload.data || {},
    icon: '/icons/Icon-192.png',
  };
  return self.registration.showNotification(title, options);
});

self.addEventListener('notificationclick', function (event) {
  event.notification.close();
  const route = event.notification.data?.route;
  const target = route && route.startsWith('/')
    ? `${self.location.origin}/#${route}`
    : self.location.origin;
  event.waitUntil(clients.openWindow(target));
});
