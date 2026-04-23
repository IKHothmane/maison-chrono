import { useEffect, useMemo, useState } from 'react'
import { useSearchParams } from 'react-router-dom'

import Notice from '../components/Notice.jsx'
import ProductCard from '../components/ProductCard.jsx'
import { listBrands, listProducts } from '../lib/api/catalog.js'
import { isSupabaseConfigured } from '../lib/supabaseClient.js'

export default function Catalog() {
  const [searchParams] = useSearchParams()
  const [brands, setBrands] = useState([])
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

    Promise.all([listBrands(), listProducts(query)])
      .then(([rows, data]) => {
        if (cancelled) return
        setBrands(rows ?? [])
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

  const productsByBrandId = useMemo(() => {
    const map = new Map()
    const noBrandKey = 'no-brand'
    for (const p of products) {
      const brandId = p?.brands?.id ?? null
      const key = brandId ?? noBrandKey
      const list = map.get(key) ?? []
      list.push(p)
      map.set(key, list)
    }
    for (const [brandId, list] of map.entries()) {
      list.sort((a, b) => {
        const ta = a?.created_at ? new Date(a.created_at).getTime() : 0
        const tb = b?.created_at ? new Date(b.created_at).getTime() : 0
        return tb - ta
      })
      map.set(brandId, list)
    }
    return map
  }, [products])

  const sections = useMemo(() => {
    const list = (brands ?? [])
      .map((b) => ({ key: `brand:${b.id}`, title: b.name, products: productsByBrandId.get(b.id) ?? [] }))
      .filter((x) => x.products.length > 0)

    const noBrand = productsByBrandId.get('no-brand') ?? []
    if (noBrand.length > 0) {
      list.push({ key: 'brand:none', title: 'Autres', products: noBrand })
    }

    return list
  }, [brands, productsByBrandId])

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
          {sections.map(({ key, title, products: brandProducts }) => (
            <section key={key} className="mc-section">
              <div className="mc-section__head">
                <h2 className="mc-section__title">{title}</h2>
              </div>
              <div className="mc-grid mc-grid--catalog">
                {brandProducts.map((p) => (
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
