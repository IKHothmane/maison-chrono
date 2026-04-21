import { supabase } from '../supabaseClient.js'

function ensureSupabase() {
  if (!supabase) {
    throw new Error(
      'Supabase non configuré. Renseigne VITE_SUPABASE_URL et VITE_SUPABASE_ANON_KEY.',
    )
  }
}

export async function listReels() {
  ensureSupabase()
  const { data, error } = await supabase
    .from('product_videos')
    .select('id, public_url, storage_path, product_id, products(id, name)')
    .order('sort_order', { ascending: true })
    .order('created_at', { ascending: false })

  if (error) throw error
  return (data ?? [])
    .map((r) => {
      const publicUrl = String(r?.public_url ?? '').trim()
      if (publicUrl) return { ...r, public_url: publicUrl }
      const storagePath = String(r?.storage_path ?? '').trim()
      if (!storagePath) return { ...r, public_url: '' }
      const { data: urlData } = supabase.storage.from('product-videos').getPublicUrl(storagePath)
      return { ...r, public_url: String(urlData?.publicUrl ?? '') }
    })
    .filter((r) => r?.public_url)
}

export async function listProductVideos(productId) {
  ensureSupabase()
  const { data, error } = await supabase
    .from('product_videos')
    .select('id, public_url, storage_path')
    .eq('product_id', productId)
    .order('sort_order', { ascending: true })
    .order('created_at', { ascending: true })

  if (error) throw error
  return (data ?? [])
    .map((r) => {
      const publicUrl = String(r?.public_url ?? '').trim()
      if (publicUrl) return { ...r, public_url: publicUrl }
      const storagePath = String(r?.storage_path ?? '').trim()
      if (!storagePath) return { ...r, public_url: '' }
      const { data: urlData } = supabase.storage.from('product-videos').getPublicUrl(storagePath)
      return { ...r, public_url: String(urlData?.publicUrl ?? '') }
    })
    .filter((r) => r?.public_url)
}
