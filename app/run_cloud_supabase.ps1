$root = Split-Path -Parent $PSScriptRoot
Set-Location $root
flutter run -d windows --dart-define=SUPABASE_URL=https://uslcbhozuyyfnencttol.supabase.co --dart-define=SUPABASE_ANON_KEY=sb_publishable_8ZfvWocrUKREOAwU8CjRdA_qK_jHuT3
