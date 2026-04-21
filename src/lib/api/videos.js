import { supabase } from '../supabaseClient.js'

const DEBUG =
  Boolean(import.meta?.env?.DEV) || String(import.meta?.env?.VITE_DEBUG ?? '') === '1'

function log(...args) {
  if (!DEBUG) return
  console.log('[MaisonChrono][videos]', ...args)
}

function ensureSupabase() {
  if (!supabase) {
    throw new Error(
      'Supabase non configuré. Renseigne VITE_SUPABASE_URL et VITE_SUPABASE_ANON_KEY.',
    )
  }
}

export async function listReels() {
  ensureSupabase()
  log('listReels start')
  const { data, error } = await supabase
    .from('product_videos')
    .select('id, public_url, storage_path, product_id, products(id, name)')
    .order('sort_order', { ascending: true })
    .order('created_at', { ascending: false })

  if (error) throw error
  log('listReels ok', (data ?? []).length)
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
  log('listProductVideos start', productId)
  const { data, error } = await supabase
    .from('product_videos')
    .select('id, public_url, storage_path')
    .eq('product_id', productId)
    .order('sort_order', { ascending: true })
    .order('created_at', { ascending: true })

  if (error) throw error
  log('listProductVideos ok', (data ?? []).length)
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
