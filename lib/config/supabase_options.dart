/// Supabase project credentials.
///
/// Replace the placeholder values below with your actual Supabase project URL
/// and anon (public) key from:
///   https://supabase.com/dashboard/project/YOUR_PROJECT_ID/settings/api
///
/// Required Supabase Storage setup:
///   1. Create a storage bucket named "photos" (set to public).
///   2. Enable anonymous auth in Supabase Auth.
///   3. Add storage policies that allow authenticated uploads and public reads.
class SupabaseOptions {
  SupabaseOptions._();

  static const String url = 'https://vomlelloeezuaieiaozz.supabase.co';
  static const String anonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZvbWxlbGxvZWV6dWFpZWlhb3p6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzM0OTgzODYsImV4cCI6MjA4OTA3NDM4Nn0.FflBuyAOH5W44righXX3Fv-Jdw3p9McrprUwAP1z1Pk';

  /// Bucket name used for all app images (member photos, notice images, etc.)
  static const String photosBucket = 'photos';
}
