import { useCallback, useEffect, useMemo, useState } from 'react'

const STORAGE_KEY = 'mc_favorites_v1'

function safeParse(json) {
  try {
    return JSON.parse(json)
  } catch {
    return null
  }
}

function normalizeFavorite(product) {
  if (!product) return null
  const id = product?.id ?? null
  if (id == null) return null
  return {
    id,
    name: product?.name ?? '',
    price: product?.price ?? 0,
    compare_at_price: product?.compare_at_price ?? null,
    images: Array.isArray(product?.images) ? product.images : [],
    reference: product?.reference ?? null,
    in_stock: Boolean(product?.in_stock),
    is_featured: Boolean(product?.is_featured),
    created_at: product?.created_at ?? null,
    brands: product?.brands ? { id: product.brands.id ?? null, name: product.brands.name ?? '' } : null,
    categories: product?.categories
      ? { id: product.categories.id ?? null, name: product.categories.name ?? '', slug: product.categories.slug ?? null }
      : null,
  }
}

export function readFavorites() {
  if (typeof window === 'undefined') return []
  const raw = window.localStorage?.getItem?.(STORAGE_KEY)
  if (!raw) return []
  const parsed = safeParse(raw)
  if (!Array.isArray(parsed)) return []
  return parsed.filter((x) => x && (x.id ?? null) != null)
}

function writeFavorites(items) {
  if (typeof window === 'undefined') return
  window.localStorage?.setItem?.(STORAGE_KEY, JSON.stringify(items ?? []))
}

export function useFavorites() {
  const [favorites, setFavorites] = useState(() => readFavorites())

  useEffect(() => {
    function onStorage(e) {
      if (e.key !== STORAGE_KEY) return
      setFavorites(readFavorites())
    }
    window.addEventListener('storage', onStorage)
    return () => window.removeEventListener('storage', onStorage)
  }, [])

  const favoriteIdSet = useMemo(() => {
    const set = new Set()
    for (const f of favorites) set.add(String(f.id))
    return set
  }, [favorites])

  const isFavorite = useCallback((id) => favoriteIdSet.has(String(id)), [favoriteIdSet])

  const toggleFavorite = useCallback((product) => {
    const snap = normalizeFavorite(product)
    if (!snap) return
    setFavorites((prev) => {
      const id = String(snap.id)
      const exists = prev.some((x) => String(x.id) === id)
      const next = exists ? prev.filter((x) => String(x.id) !== id) : [snap, ...prev]
      writeFavorites(next)
      return next
    })
  }, [])

  const removeFavorite = useCallback((id) => {
    setFavorites((prev) => {
      const next = prev.filter((x) => String(x.id) !== String(id))
      writeFavorites(next)
      return next
    })
  }, [])

  const clearFavorites = useCallback(() => {
    setFavorites(() => {
      writeFavorites([])
      return []
    })
  }, [])

  return { favorites, isFavorite, toggleFavorite, removeFavorite, clearFavorites }
}
