import { useEffect, useMemo, useState } from 'react'
import { useSearchParams } from 'react-router-dom'

import Notice from '../components/Notice.jsx'
import ProductCard from '../components/ProductCard.jsx'
import { listProducts } from '../lib/api/catalog.js'
import { isSupabaseConfigured } from '../lib/supabaseClient.js'

export default function Catalog() {
  const [searchParams] = useSearchParams()
  const [products, setProducts] = useState([])
  const [page, setPage] = useState(1)

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

    listProducts(query)
      .then((data) => {
        if (cancelled) return
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

  const pageSize = 24
  const total = products.length
  const totalPages = Math.max(1, Math.ceil(total / pageSize))
  const safePage = Math.min(page, totalPages)
  const pagedProducts = useMemo(() => {
    const start = (safePage - 1) * pageSize
    return products.slice(start, start + pageSize)
  }, [safePage, products])

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

      {pagedProducts.length > 0 ? (
        <section className="mc-section">
          <div className="mc-grid mc-grid--catalog">
            {pagedProducts.map((p) => (
              <ProductCard key={p.id} product={p} />
            ))}
          </div>
        </section>
      ) : null}

      {status === 'success' && totalPages > 1 ? (
        <div className="mc-pagination">
          <button
            className="mc-btn mc-btn--ghost"
            type="button"
            onClick={() => setPage((p) => Math.max(1, p - 1))}
            disabled={safePage <= 1}
          >
            Précédent
          </button>
          <div className="mc-muted">
            Page {safePage} / {totalPages}
          </div>
          <button
            className="mc-btn mc-btn--ghost"
            type="button"
            onClick={() => setPage((p) => Math.min(totalPages, p + 1))}
            disabled={safePage >= totalPages}
          >
            Suivant
          </button>
        </div>
      ) : null}
    </div>
  )
}
