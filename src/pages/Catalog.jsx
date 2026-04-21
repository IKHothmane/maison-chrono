import { useEffect, useMemo, useState } from 'react'
import { useSearchParams } from 'react-router-dom'

import Notice from '../components/Notice.jsx'
import ProductCard from '../components/ProductCard.jsx'
import { listCategories, listProducts } from '../lib/api/catalog.js'
import { isSupabaseConfigured } from '../lib/supabaseClient.js'

export default function Catalog() {
  const [searchParams] = useSearchParams()
  const [categories, setCategories] = useState([])
  const [products, setProducts] = useState([])

  const [error, setError] = useState(null)
  const [loadedKey, setLoadedKey] = useState(null)

  const urlSearch = searchParams.get('q') ?? ''
  const activeTab = searchParams.get('tab') ?? 'all'

  const query = useMemo(() => {
    return {
      search: urlSearch,
      tab: activeTab,
    }
  }, [urlSearch, activeTab])

  useEffect(() => {
    if (!isSupabaseConfigured()) return
    let cancelled = false

    Promise.all([listCategories(), listProducts(query)])
      .then(([cats, data]) => {
        if (cancelled) return
        setCategories(cats ?? [])
        setProducts(data)
        setError(null)
        setLoadedKey(JSON.stringify(query))
      })
      .catch((err) => {
        if (cancelled) return
        setError(err)
        setLoadedKey(JSON.stringify(query))
      })

    return () => {
      cancelled = true
    }
  }, [query])

  const queryKey = JSON.stringify(query)

  const status = !isSupabaseConfigured()
    ? 'idle'
    : loadedKey === queryKey
      ? error
        ? 'error'
        : 'success'
      : 'loading'

  const productsByCategoryId = useMemo(() => {
    const map = new Map()
    for (const p of products) {
      const catId = p?.categories?.id ?? null
      if (!catId) continue
      const list = map.get(catId) ?? []
      list.push(p)
      map.set(catId, list)
    }
    for (const [catId, list] of map.entries()) {
      list.sort((a, b) => {
        const ta = a?.created_at ? new Date(a.created_at).getTime() : 0
        const tb = b?.created_at ? new Date(b.created_at).getTime() : 0
        return tb - ta
      })
      map.set(catId, list)
    }
    return map
  }, [products])

  const sections = useMemo(() => {
    return (categories ?? [])
      .map((c) => ({ category: c, products: productsByCategoryId.get(c.id) ?? [] }))
      .filter((x) => x.products.length > 0)
  }, [categories, productsByCategoryId])

  const total = products.length

  return (
    <div className="mc-catalog">
      {!isSupabaseConfigured() ? (
        <Notice title="Supabase non configuré" tone="danger">
          Configure <span className="mc-code">VITE_SUPABASE_URL</span> et{' '}
          <span className="mc-code">VITE_SUPABASE_ANON_KEY</span> pour activer le catalogue.
        </Notice>
      ) : null}

      {status === 'loading' ? <div className="mc-muted">Chargement…</div> : null}
      {status === 'error' ? (
        <Notice title="Erreur de chargement" tone="danger">
          {String(error?.message ?? error)}
        </Notice>
      ) : null}

      {status === 'success' && total === 0 ? <div className="mc-muted">Aucun résultat.</div> : null}

      {status === 'success' && sections.length > 0 ? (
        <div className="mc-stack">
          {sections.map(({ category, products: catProducts }) => (
            <section key={category.id} className="mc-section">
              <div className="mc-section__head">
                <h2 className="mc-section__title">{category.name}</h2>
              </div>
              <div className="mc-grid mc-grid--catalog">
                {catProducts.map((p) => (
                  <ProductCard key={p.id} product={p} />
                ))}
              </div>
            </section>
          ))}
        </div>
      ) : null}
    </div>
  )
}
