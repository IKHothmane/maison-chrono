import { motion } from 'framer-motion'
import { useEffect, useMemo, useState } from 'react'

import Notice from '../components/Notice.jsx'
import ProductCard from '../components/ProductCard.jsx'
import hero1Img from '../assets/hero1.png'
import { listCategories, listProducts } from '../lib/api/catalog.js'
import { getSupabaseConfig, isSupabaseConfigured } from '../lib/supabaseClient.js'

const ACCROCHES = [
  'Le luxe à votre portée.',
  'L’excellence, tout simplement.',
  'Votre prochaine montre est ici.',
  'Le temps, en version luxe.',
  'Signez votre style.',
]

const STYLES = [
  {
    title: 'Les Iconiques',
    desc: 'Les modèles légendaires (Submariner, Speedmaster, Tank).',
  },
  {
    title: 'Sport & Performance',
    desc: 'Montres de plongée, chronographes et modèles robustes.',
  },
  {
    title: 'Classique & Soirée',
    desc: 'Montres habillées, fines et élégantes.',
  },
  {
    title: 'Haute Horlogerie',
    desc: 'Modèles à complications (Tourbillons, Calendriers perpétuels).',
  },
]

export default function Home() {
  const MotionDiv = motion.div
  const supabaseConfig = useMemo(() => getSupabaseConfig(), [])
  const [accrocheIndex, setAccrocheIndex] = useState(0)
  const [categories, setCategories] = useState([])
  const [products, setProducts] = useState([])
  const [loaded, setLoaded] = useState(false)
  const [error, setError] = useState(null)

  useEffect(() => {
    const id = window.setInterval(() => {
      setAccrocheIndex((i) => (i + 1) % ACCROCHES.length)
    }, 4200)
    return () => window.clearInterval(id)
  }, [])

  useEffect(() => {
    if (!isSupabaseConfigured()) return
    let cancelled = false

    Promise.all([listCategories(), listProducts()])
      .then(([cats, prods]) => {
        if (cancelled) return
        setCategories(cats ?? [])
        setProducts(prods ?? [])
        setError(null)
        setLoaded(true)
      })
      .catch((err) => {
        if (cancelled) return
        setError(err)
        setLoaded(true)
      })

    return () => {
      cancelled = true
    }
  }, [])

  const status = !isSupabaseConfigured() ? 'idle' : loaded ? (error ? 'error' : 'success') : 'loading'

  const productsByCategoryId = useMemo(() => {
    const map = new Map()
    for (const p of products) {
      const catId = p?.categories?.id ?? null
      if (!catId) continue
      const list = map.get(catId) ?? []
      list.push(p)
      map.set(catId, list)
    }
    return map
  }, [products])

  return (
    <div className="mc-stack">
      {!isSupabaseConfigured() ? (
        <Notice title="Supabase non configuré" tone="danger">
          Renseigne <span className="mc-code">VITE_SUPABASE_URL</span> et{' '}
          <span className="mc-code">VITE_SUPABASE_ANON_KEY</span> dans un fichier{' '}
          <span className="mc-code">web/.env.local</span>.
          <div className="mc-space-sm" />
          <div className="mc-muted">
            Valeurs actuelles : URL={supabaseConfig.supabaseUrl ? 'OK' : 'manquante'} · KEY=
            {supabaseConfig.supabaseAnonKey ? 'OK' : 'manquante'}
          </div>
        </Notice>
      ) : null}

      <section className="mc-heroBanner" aria-label="Hero">
        <img className="mc-heroBanner__img" src={hero1Img} alt="" loading="eager" />
      </section>

      <section className="mc-accroche" aria-label="Accroche">
        <div className="mc-accroche__inner">
          <MotionDiv
            key={accrocheIndex}
            initial={{ opacity: 0, y: 8 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.45, ease: 'easeOut' }}
          >
            <div className="mc-accroche__text">{ACCROCHES[accrocheIndex]}</div>
          </MotionDiv>
        </div>
      </section>

      <section className="mc-section">
        <div className="mc-section__head">
          <h2 className="mc-section__title">Par style</h2>
        </div>

        <MotionDiv
          className="mc-grid mc-grid--styles"
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          transition={{ duration: 0.35, ease: 'easeOut' }}
        >
          {STYLES.map((s) => (
            <div key={s.title} className="mc-styleCard">
              <div className="mc-styleCard__title">{s.title}</div>
              <div className="mc-styleCard__desc">{s.desc}</div>
            </div>
          ))}
        </MotionDiv>
      </section>

      {status === 'loading' ? <div className="mc-muted">Chargement…</div> : null}
      {status === 'error' ? (
        <Notice title="Impossible de charger les produits" tone="danger">
          {String(error?.message ?? error)}
        </Notice>
      ) : null}

      {status === 'success' ? (
        <div className="mc-stack">
          {categories
            .map((c) => ({ category: c, products: productsByCategoryId.get(c.id) ?? [] }))
            .filter((x) => x.products.length > 0)
            .map(({ category, products: catProducts }) => (
              <section key={category.id} className="mc-section">
                <div className="mc-section__head">
                  <h2 className="mc-section__title">{category.name}</h2>
                </div>
                <div className="mc-grid">
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
