import { motion } from 'framer-motion'
import { useEffect, useMemo, useState } from 'react'

import Notice from '../components/Notice.jsx'
import ProductCard from '../components/ProductCard.jsx'
import hero1Img from '../assets/hero1.png'
import { listCategories, listProducts } from '../lib/api/catalog.js'
import { getSupabaseConfig, isSupabaseConfigured } from '../lib/supabaseClient.js'

const ACCROCHES = [
  'Le luxe à votre portée.',
  `L'excellence, tout simplement.`,
  'Votre prochaine montre est ici.',
  'Le temps, en version luxe.',
  'Signez votre style.',
]

const STYLES = [
  {
    title: 'Les Iconiques',
    desc: 'Les modèles légendaires (Submariner, Speedmaster, Tank).',
    icon: '👑',
  },
  {
    title: 'Sport & Performance',
    desc: 'Montres de plongée, chronographes et modèles robustes.',
    icon: '⚡',
  },
  {
    title: 'Classique & Soirée',
    desc: 'Montres habillées, fines et élégantes.',
    icon: '✨',
  },
  {
    title: 'Haute Horlogerie',
    desc: 'Modèles à complications (Tourbillons, Calendriers perpétuels).',
    icon: '🔮',
  },
]

const containerVariants = {
  hidden: { opacity: 0 },
  visible: {
    opacity: 1,
    transition: {
      staggerChildren: 0.1,
      delayChildren: 0.1,
    },
  },
}

const itemVariants = {
  hidden: { opacity: 0, y: 20 },
  visible: {
    opacity: 1,
    y: 0,
    transition: { duration: 0.5, ease: [0.4, 0, 0.2, 1] },
  },
}

function SkeletonGrid() {
  return (
    <div className="mc-grid">
      {[1, 2, 3].map((i) => (
        <div key={i} className="mc-skeleton mc-skeleton--card" />
      ))}
    </div>
  )
}

export default function Home() {
  const MotionDiv = motion.div
  const MotionSection = motion.section
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

      <MotionSection
        className="mc-heroBanner"
        aria-label="Hero"
        initial={{ opacity: 0, y: 30 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ duration: 0.8, ease: [0.4, 0, 0.2, 1] }}
      >
        <img className="mc-heroBanner__img" src={hero1Img} alt="" loading="eager" />
      </MotionSection>

      <MotionSection
        className="mc-accroche"
        aria-label="Accroche"
        initial={{ opacity: 0 }}
        animate={{ opacity: 1 }}
        transition={{ duration: 0.6, delay: 0.3 }}
      >
        <div className="mc-accroche__inner">
          <MotionDiv
            key={accrocheIndex}
            initial={{ opacity: 0, y: 12, scale: 0.97 }}
            animate={{ opacity: 1, y: 0, scale: 1 }}
            exit={{ opacity: 0, y: -8 }}
            transition={{ duration: 0.5, ease: [0.4, 0, 0.2, 1] }}
          >
            <div className="mc-accroche__text">{ACCROCHES[accrocheIndex]}</div>
          </MotionDiv>
        </div>
      </MotionSection>

      <MotionSection
        className="mc-section"
        initial={{ opacity: 0, y: 20 }}
        whileInView={{ opacity: 1, y: 0 }}
        viewport={{ once: true, margin: '-80px' }}
        transition={{ duration: 0.6, ease: [0.4, 0, 0.2, 1] }}
      >
        <div className="mc-section__head">
          <h2 className="mc-section__title">Par style</h2>
        </div>

        <MotionDiv
          className="mc-grid mc-grid--styles"
          variants={containerVariants}
          initial="hidden"
          whileInView="visible"
          viewport={{ once: true, margin: '-60px' }}
        >
          {STYLES.map((s) => (
            <MotionDiv key={s.title} className="mc-styleCard" variants={itemVariants}>
              <div style={{ fontSize: '28px', marginBottom: '10px' }}>{s.icon}</div>
              <div className="mc-styleCard__title">{s.title}</div>
              <div className="mc-styleCard__desc">{s.desc}</div>
            </MotionDiv>
          ))}
        </MotionDiv>
      </MotionSection>

      {status === 'loading' ? <SkeletonGrid /> : null}
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
              <MotionSection
                key={category.id}
                className="mc-section"
                initial={{ opacity: 0, y: 20 }}
                whileInView={{ opacity: 1, y: 0 }}
                viewport={{ once: true, margin: '-60px' }}
                transition={{ duration: 0.6, ease: [0.4, 0, 0.2, 1] }}
              >
                <div className="mc-section__head">
                  <h2 className="mc-section__title">{category.name}</h2>
                </div>
                <div className="mc-grid">
                  {catProducts.map((p, idx) => (
                    <ProductCard key={p.id} product={p} index={idx} />
                  ))}
                </div>
              </MotionSection>
            ))}
        </div>
      ) : null}
    </div>
  )
}
