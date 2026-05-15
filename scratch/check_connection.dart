import 'package:supabase/supabase.dart';

void main() async {
  const url = 'https://jqyjvhwlcqcsuwcqgcwf.supabase.co';
  const key = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImpxeWp2aHdsY3Fjc3V3Y3FnY3dmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzg1MjI4MjgsImV4cCI6MjA5NDA5ODgyOH0.3bF68bNG0IwAc50YbOC3sem4k8O-d1vkvNNqBt1HbRw';

  final client = SupabaseClient(url, key);

  try {
    print('Connecting to Supabase...');
    final response = await client.from('posts').select().limit(1);
    print('Connection successful! Found ${response.length} posts.');

    final products = await client.from('products').select().limit(1);
    print('Products table exists! Found ${products.length} products.');
  } catch (e) {
    print('Connection failed or table does not exist: $e');
  }
}
