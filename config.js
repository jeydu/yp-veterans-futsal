// Website settings shared by index.html and admin.html.
//
// Supabase (the online database for registrations and ID photos):
// paste your project's URL and its publishable / anon key here.
// Find them in Supabase: Project Settings -> API (or "Connect").
// The publishable key is safe to put in a website; the security rules in
// supabase/setup.sql control what the public can do with it.
//
// Leave both empty to keep registrations going to WhatsApp only.
window.YP_CONFIG = {
  supabaseUrl: "https://ooofcwqeosatktwlahnq.supabase.co",
  supabaseKey: "sb_publishable_GF-gpMQn6U2i2V5S-TJwDA_8Cuz8Vcd",

  // Organiser's WhatsApp number, country code first, no "+" or spaces
  whatsapp: "9609751808"
};
