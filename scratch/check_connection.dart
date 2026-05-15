import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  const url = 'https://jqyjvhwlcqcsuwcqgcwf.supabase.co';
  const key = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImpxeWp2aHdsY3Fjc3V3Y3FnY3dmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzg1MjI4MjgsImV4cCI6MjA5NDA5ODgyOH0.3bF68bNG0IwAc50YbOC3sem4k8O-d1vkvNNqBt1HbRw';

  final client = SupabaseClient(url, key);

  try {
    stdout.writeln('Connecting to Supabase...');
    final response = await client.from('posts').select().limit(1);
    stdout.writeln('Connection successful! Found ${response.length} posts.');

    final products = await client.from('products').select().limit(1);
    stdout.writeln('Products table exists! Found ${products.length} products.');
  } catch (e) {
    stdout.writeln('Connection failed or table does not exist: $e');
  }
}
