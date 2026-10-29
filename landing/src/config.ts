// Where the beta sign-ups go: the IngatanKu Supabase project's
// `beta-signup` edge function. The publishable key is public (the app
// ships it too); the function itself decides what gets in.
export const SUPABASE_URL = 'https://hopdujkhmsgvseuaxbba.supabase.co';
export const SUPABASE_PUBLISHABLE_KEY = 'sb_publishable_RJ9gdr2UBAjEt2kb4dwKZA_8zfUtw6-';
export const BETA_SIGNUP_URL = `${SUPABASE_URL}/functions/v1/beta-signup`;
