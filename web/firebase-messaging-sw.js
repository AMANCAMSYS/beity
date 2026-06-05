importScripts('https://www.gstatic.com/firebasejs/10.12.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.12.0/firebase-messaging-compat.js');

firebase.initializeApp({
  apiKey: 'AIzaSyDjzY6gV7MQ30zNXyMKUECvqiiYwaYFv-8',
  appId: '1:977923653056:web:ee82acc21f07eacd4d9c25',
  messagingSenderId: '977923653056',
  projectId: 'sawa-5c4e0',
  storageBucket: 'sawa-5c4e0.firebasestorage.app',
  authDomain: 'sawa-5c4e0.firebaseapp.com',
  measurementId: 'G-WXVLKJLDMJ',
});

firebase.messaging();
