
import 'package:flutter/material.dart';

// Helper to map feature text to icons
class FeaturesData {
  static IconData getFeatureIcon(String feature) {
    final lower = feature.toLowerCase();
    if (lower.contains('wifi') || lower.contains('net')) return Icons.wifi;
    if (lower.contains('air') || lower.contains('ac') || lower.contains('cool')) return Icons.ac_unit;
    if (lower.contains('park') || lower.contains('garage')) return Icons.local_parking;
    if (lower.contains('pool') || lower.contains('swim')) return Icons.pool;
    if (lower.contains('gym') || lower.contains('fitness')) return Icons.fitness_center;
    if (lower.contains('security') || lower.contains('guard') || lower.contains('cctv')) return Icons.security;
    if (lower.contains('balcony') || lower.contains('patio')) return Icons.balcony;
    if (lower.contains('furnish') || lower.contains('sofa')) return Icons.chair;
    if (lower.contains('kitchen') || lower.contains('cook')) return Icons.kitchen;
    if (lower.contains('tv') || lower.contains('tele')) return Icons.tv;
    if (lower.contains('wash') || lower.contains('laundry')) return Icons.local_laundry_service;
    if (lower.contains('elevator') || lower.contains('lift')) return Icons.elevator;
    if (lower.contains('pet') || lower.contains('dog') || lower.contains('cat')) return Icons.pets;
    
    return Icons.check_circle_outline; // Default fallback icon
  }
}