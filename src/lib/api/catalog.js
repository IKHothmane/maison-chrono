import { supabase } from '../supabaseClient.js'

function ensureSupabase() {
  if (!supabase) {
    throw new Error(
      'Supabase non configuré. Renseigne VITE_SUPABASE_URL et VITE_SUPABASE_ANON_KEY.',
    )
  }
}

export async function listBrands() {
  ensureSupabase()
  const { data, error } = await supabase
    .from('brands')
    .select('id,name,logo_url,description')
    .order('name', { ascending: true })

  if (error) throw error
  return data ?? []
}

export async function listCategories() {
  ensureSupabase()
  const { data, error } = await supabase
    .from('categories')
    .select('id,name,slug')
    .order('name', { ascending: true })

  if (error) throw error
  return data ?? []
}

export async function listProducts({
  search,
  brandId,
  categoryId,
  minPrice,
  maxPrice,
  featured,
  tab,
} = {}) {
  ensureSupabase()
  async function runSelect(selectList, { requirePublished, allowPromo, allowBestSeller } = {}) {
    const promoEnabled = allowPromo !== false
    const bestEnabled = allowBestSeller !== false
    let query = supabase
      .from('products')
      .select(selectList)

    if (featured === true || tab === 'featured') query = query.eq('is_featured', true)
    if (promoEnabled && tab === 'promo') query = query.not('compare_at_price', 'is', null)
    if (requirePublished === true) query = query.eq('is_published', true)
    if (brandId) query = query.eq('brand_id', brandId)
    if (categoryId) query = query.eq('category_id', categoryId)
    if (typeof minPrice === 'number') query = query.gte('price', minPrice)
    if (typeof maxPrice === 'number') query = query.lte('price', maxPrice)
    if (search?.trim()) query = query.ilike('name', `%${search.trim()}%`)

    if (bestEnabled && tab === 'best') {
      query = query
        .not('best_seller_rank', 'is', null)
        .order('best_seller_rank', { ascending: true })
        .order('created_at', { ascending: false })
    } else {
      query = query.order('created_at', { ascending: false })
    }

    const { data, error } = await query
    if (error) throw error
    return data ?? []
  }

  try {
    return await runSelect(
      'id,name,price,compare_at_price,best_seller_rank,images,reference,in_stock,is_featured,created_at,brands(id,name),categories(id,name,slug)',
      { requirePublished: true },
    )
  } catch (e) {
    if (e?.code === '42703') {
      try {
        return await runSelect(
          'id,name,price,compare_at_price,images,reference,in_stock,is_featured,created_at,brands(id,name),categories(id,name,slug)',
          { requirePublished: true, allowBestSeller: false },
        )
      } catch (e2) {
        if (e2?.code === '42703') {
          try {
            return await runSelect(
              'id,name,price,images,reference,in_stock,is_featured,created_at,brands(id,name),categories(id,name,slug)',
              { requirePublished: true, allowPromo: false, allowBestSeller: false },
            )
          } catch (e3) {
            if (e3?.code === '42703') {
              return await runSelect(
                'id,name,price,images,reference,in_stock,is_featured,created_at,brands(id,name),categories(id,name,slug)',
              )
            }
            throw e3
          }
        }
        throw e2
      }
    }
    throw e
  }
}

export async function getProductById(id) {
  ensureSupabase()
  async function runSelect(selectList, { requirePublished } = {}) {
    let query = supabase
      .from('products')
      .select(selectList)
      .eq('id', id)
    if (requirePublished === true) query = query.eq('is_published', true)
    const { data, error } = await query.maybeSingle()
    if (error) throw error
    return data ?? null
  }

  try {
    return await runSelect(
      'id,name,price,compare_at_price,description,images,reference,material,movement,water_resistance,diameter,in_stock,is_featured,created_at,brands(id,name,logo_url,description),categories(id,name,slug)',
      { requirePublished: true },
    )
  } catch (e) {
    if (e?.code === '42703') {
      try {
        return await runSelect(
          'id,name,price,description,images,reference,material,movement,water_resistance,diameter,in_stock,is_featured,created_at,brands(id,name,logo_url,description),categories(id,name,slug)',
          { requirePublished: true },
        )
      } catch (e2) {
        if (e2?.code === '42703') {
          return await runSelect(
            'id,name,price,description,images,reference,material,movement,water_resistance,diameter,in_stock,is_featured,created_at,brands(id,name,logo_url,description),categories(id,name,slug)',
          )
        }
        throw e2
      }
    }
    throw e
  }
}
