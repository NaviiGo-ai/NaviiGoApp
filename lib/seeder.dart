import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> seedDatabase() async {
  final firestore = FirebaseFirestore.instance;

  final destinations = [
    {
      'title': 'George Everest',
      'subtitle': 'Mussoorie, Uttarakhand',
      'image': 'https://images.unsplash.com/photo-1623869688537-88287ea6de72?auto=format&fit=crop&q=80',
      'rating': 4.8,
    },
    {
      'title': 'Rishikesh',
      'subtitle': 'Yoga Capital, India',
      'image': 'https://images.unsplash.com/photo-1626297375253-15714041b312?auto=format&fit=crop&q=80',
      'rating': 4.9,
    },
    {
      'title': 'Auli Ski Resort',
      'subtitle': 'Chamoli, Uttarakhand',
      'image': 'https://images.unsplash.com/photo-1644342371408-ebef0f1710b1?auto=format&fit=crop&q=80',
      'rating': 4.7,
    },
  ];

  final articles = [
    {
      'title': 'The Art of Slow Wandering',
      'subtitle': 'Discovering the unseen paths in the Himalayas',
      'image': 'https://images.unsplash.com/photo-1469854523086-cc02fe5d8800?auto=format&fit=crop&q=80',
      'tag': 'TIPS',
    },
    {
      'title': 'Packing for the Monsoon',
      'subtitle': 'Essential gear for the Western Ghats',
      'image': 'https://images.unsplash.com/photo-1501555088652-021faa106b9b?auto=format&fit=crop&q=80',
      'tag': 'GUIDE',
    },
  ];

  final itineraries = [
    {
      'title': 'Kyoto Heritage Trail',
      'subtitle': '7 Days • Historical Sites • Cultural immersion',
      'image': 'https://images.unsplash.com/photo-1493976040374-85c8e12f0c0e?auto=format&fit=crop&q=80',
      'rating': 4.9,
      'memberCount': 24,
    },
    {
      'title': 'Swiss Alps Explorer',
      'subtitle': '10 Days • Adventure • Scenic Railways',
      'image': 'https://images.unsplash.com/photo-1530122037265-a5f1f91d3b99?auto=format&fit=crop&q=80',
      'rating': 4.8,
      'memberCount': 12,
    },
  ];

  for (var dest in destinations) {
    await firestore.collection('destinations').add(dest);
  }
  for (var art in articles) {
    await firestore.collection('journal_articles').add(art);
  }
  for (var iti in itineraries) {
    await firestore.collection('premium_itineraries').add(iti);
  }
  
  debugPrint("✅ Database Seeded Successfully!");
}
