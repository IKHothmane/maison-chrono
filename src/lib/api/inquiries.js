import { supabase } from '../supabaseClient.js'

function ensureSupabase() {
  if (!supabase) {
    throw new Error(
      'Supabase non configuré. Renseigne VITE_SUPABASE_URL et VITE_SUPABASE_ANON_KEY.',
    )
  }
}

export async function createInquiry({ productId, name, email, phone, city, address }) {
  ensureSupabase()
  const payload = {
    product_id: productId ?? null,
    name,
    email: email?.trim() ? email.trim() : '',
    phone: phone?.trim() ? phone.trim() : null,
    city: city?.trim() ? city.trim() : null,
    address: address?.trim() ? address.trim() : null,
    message: '',
  }

  const { error } = await supabase.from('inquiries').insert(payload)
  if (error) {
    const code = error?.code ?? ''
    const msg = String(error?.message ?? error)
    if (code === '42501' || msg.toLowerCase().includes('row-level security')) {
      throw new Error(
        'Envoi impossible: la sécurité Supabase (RLS) bloque les demandes. Active la policy INSERT sur la table "inquiries" pour anon/authenticated. Si tu utilises .select() après insert, il faut aussi une policy SELECT (sinon Supabase bloque le retour).',
      )
    }
    throw error
  }

  try {
    await supabase.functions.invoke('notify_inquiry', {
      body: {
        name,
        phone: phone?.trim() ? phone.trim() : null,
        email: email?.trim() ? email.trim() : null,
        city: city?.trim() ? city.trim() : null,
        address: address?.trim() ? address.trim() : null,
        productId: productId ?? null,
      },
    })
  } catch (e) {
    void e
  }

  return { id: null }
}
