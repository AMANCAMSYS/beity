importScripts('https://www.gstatic.com/firebasejs/10.12.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.12.0/firebase-messaging-compat.js');

firebase.initializeApp({
  apiKey: 'AIzaSyBO_SST1Zs7Ae6Ww4Rfy5t8Sc8gh66FpCU',
  appId: '1:629950526379:web:d0a6305baf31bbd1af58ee',
  messagingSenderId: '629950526379',
  projectId: 'beity-ad796',
  storageBucket: 'beity-ad796.firebasestorage.app',
  authDomain: 'beity-ad796.firebaseapp.com',
});

const messaging = firebase.messaging();
