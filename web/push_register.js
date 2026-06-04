(function () {
  'use strict';

  window.PetfolioPush = {
    isSupported: function () {
      return 'serviceWorker' in navigator && 'PushManager' in window && 'Notification' in window;
    },

    register: async function (vapidPublicKey, supabaseUrl, supabaseAnonKey, accessToken) {
      if (!this.isSupported()) {
        throw new Error('Push notifications are not supported in this browser.');
      }

      var permission = await Notification.requestPermission();
      if (permission !== 'granted') {
        throw new Error('Notification permission was not granted.');
      }

      var registration = await navigator.serviceWorker.ready;
      var subscription = await registration.pushManager.subscribe({
        userVisibleOnly: true,
        applicationServerKey: urlBase64ToUint8Array(vapidPublicKey),
      });

      var json = subscription.toJSON();
      var keys = json.keys || {};

      var response = await fetch(supabaseUrl + '/functions/v1/register-web-push-subscription', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ' + accessToken,
          'apikey': supabaseAnonKey,
        },
        body: JSON.stringify({
          endpoint: json.endpoint,
          p256dh: keys.p256dh,
          auth: keys.auth,
        }),
      });

      if (!response.ok) {
        var detail = await response.text();
        throw new Error('Failed to register push subscription: ' + detail);
      }

      try {
        localStorage.setItem('petfolio_push_enabled', '1');
      } catch (_) {}

      return true;
    },
  };

  function urlBase64ToUint8Array(base64String) {
    var padding = '='.repeat((4 - (base64String.length % 4)) % 4);
    var base64 = (base64String + padding).replace(/-/g, '+').replace(/_/g, '/');
    var raw = window.atob(base64);
    var output = new Uint8Array(raw.length);
    for (var i = 0; i < raw.length; i++) {
      output[i] = raw.charCodeAt(i);
    }
    return output;
  }
}());
