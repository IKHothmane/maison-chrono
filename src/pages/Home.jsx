import { motion } from 'framer-motion'
import { useEffect, useMemo, useRef, useState } from 'react'
import { Link } from 'react-router-dom'

import Notice from '../components/Notice.jsx'
import ProductCard from '../components/ProductCard.jsx'
import actionAventureVideo from '../assets/Génération_Vidéo_Montre_Action_Aventure.mp4'
import lifestyleUrbainVideo from '../assets/Vidéo_Lifestyle_Urbain_Montre_en_Action.mp4'
import luxePresentationVideo from '../assets/Vidéo_de_présentation_de_montre_de_luxe.mp4'
import video1078589612004641 from '../assets/video-1078589612004641.mp4'
import { listProducts } from '../lib/api/catalog.js'
import { getSupabaseConfig, isSupabaseConfigured } from '../lib/supabaseClient.js'

const HERO_VIDEOS = [
  luxePresentationVideo,
  lifestyleUrbainVideo,
  actionAventureVideo,
  video1078589612004641,
]

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
    icon: 'watch',
  },
  {
    title: 'Sport & Performance',
    desc: 'Montres de plongée, chronographes et modèles robustes.',
    icon: 'diver',
  },
  {
    title: 'Classique & Soirée',
    desc: 'Montres habillées, fines et élégantes.',
    icon: 'dress',
  },
  {
    title: 'Haute Horlogerie',
    desc: 'Modèles à complications (Tourbillons, Calendriers perpétuels).',
    icon: 'movement',
  },
]

function StyleIcon({ name }) {
  if (name === 'watch') {
    return (
      <svg className="mc-styleCard__iconSvg" viewBox="0 0 24 24" fill="none" aria-hidden="true">
        <path d="M9 3h6" stroke="currentColor" strokeWidth="1.6" strokeLinecap="round" />
        <path d="M9 21h6" stroke="currentColor" strokeWidth="1.6" strokeLinecap="round" />
        <path
          d="M12 19a7 7 0 1 0 0-14 7 7 0 0 0 0 14Z"
          stroke="currentColor"
          strokeWidth="1.6"
        />
        <path d="M12 9v3.2l2.2 1.2" stroke="currentColor" strokeWidth="1.6" strokeLinecap="round" />
        <path d="M19.2 12h1.3" stroke="currentColor" strokeWidth="1.6" strokeLinecap="round" />
      </svg>
    )
  }
  if (name === 'diver') {
    return (
      <svg className="mc-styleCard__iconSvg" viewBox="0 0 24 24" fill="none" aria-hidden="true">
        <path
          d="M12 19a7 7 0 1 0 0-14 7 7 0 0 0 0 14Z"
          stroke="currentColor"
          strokeWidth="1.6"
        />
        <path
          d="M12 7.5v2.5M16.5 9l-1.7 1.1M7.5 9l1.7 1.1"
          stroke="currentColor"
          strokeWidth="1.6"
          strokeLinecap="round"
        />
        <path
          d="M12 12.2v2.8l-2.2 1.2"
          stroke="currentColor"
          strokeWidth="1.6"
          strokeLinecap="round"
        />
        <path
          d="M10 3h4"
          stroke="currentColor"
          strokeWidth="1.6"
          strokeLinecap="round"
        />
        <path
          d="M10 21h4"
          stroke="currentColor"
          strokeWidth="1.6"
          strokeLinecap="round"
        />
        <path
          d="M12 4.8c.7 0 1.4.1 2 .3"
          stroke="currentColor"
          strokeWidth="1.2"
          strokeLinecap="round"
        />
        <path
          d="M9.8 5.1c.6-.2 1.4-.3 2.2-.3"
          stroke="currentColor"
          strokeWidth="1.2"
          strokeLinecap="round"
        />
      </svg>
    )
  }
  if (name === 'dress') {
    return (
      <svg className="mc-styleCard__iconSvg" viewBox="0 0 24 24" fill="none" aria-hidden="true">
        <path d="M9.5 4h5" stroke="currentColor" strokeWidth="1.6" strokeLinecap="round" />
        <path d="M9.5 20h5" stroke="currentColor" strokeWidth="1.6" strokeLinecap="round" />
        <path
          d="M9 6.2c0-1.2 1-2.2 2.2-2.2h1.6C14 4 15 5 15 6.2v11.6c0 1.2-1 2.2-2.2 2.2h-1.6C10 20 9 19 9 17.8V6.2Z"
          stroke="currentColor"
          strokeWidth="1.6"
          strokeLinejoin="round"
        />
        <path
          d="M12 9.2v3l1.7 1"
          stroke="currentColor"
          strokeWidth="1.6"
          strokeLinecap="round"
        />
      </svg>
    )
  }
  return (
    <svg className="mc-styleCard__iconSvg" viewBox="0 0 24 24" fill="none" aria-hidden="true">
      <path
        d="M12 19a7 7 0 1 0 0-14 7 7 0 0 0 0 14Z"
        stroke="currentColor"
        strokeWidth="1.6"
      />
      <path d="M9.5 3h5" stroke="currentColor" strokeWidth="1.6" strokeLinecap="round" />
      <path d="M9.5 21h5" stroke="currentColor" strokeWidth="1.6" strokeLinecap="round" />
      <path
        d="M12 14.8a2.3 2.3 0 1 0 0-4.6 2.3 2.3 0 0 0 0 4.6Z"
        stroke="currentColor"
        strokeWidth="1.6"
      />
      <path
        d="M12 8.3v-1M12 16.7v-1M8.3 12h-1M16.7 12h-1M9.7 9.7l-.7-.7M15 15l-.7-.7M9.7 14.3l-.7.7M15 9l-.7.7"
        stroke="currentColor"
        strokeWidth="1.2"
        strokeLinecap="round"
      />
    </svg>
  )
}

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
  const heroVideoRef = useRef(null)
  const [accrocheIndex, setAccrocheIndex] = useState(0)
  const [heroVideoIndex, setHeroVideoIndex] = useState(0)
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

    listProducts()
      .then((prods) => {
        if (cancelled) return
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

  const latestProducts = useMemo(() => {
    const list = Array.isArray(products) ? [...products] : []
    list.sort((a, b) => {
      const ta = a?.created_at ? new Date(a.created_at).getTime() : 0
      const tb = b?.created_at ? new Date(b.created_at).getTime() : 0
      return tb - ta
    })
    return list.slice(0, 12)
  }, [products])

  const heroVideoSrc = HERO_VIDEOS[heroVideoIndex % HERO_VIDEOS.length]

  useEffect(() => {
    const video = heroVideoRef.current
    if (!video) return
    try {
      video.load()
      const p = video.play()
      if (p && typeof p.catch === 'function') p.catch(() => {})
    } catch {
      null
    }
  }, [heroVideoSrc])

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
        <video
          className="mc-heroBanner__video"
          src={heroVideoSrc}
          muted
          playsInline
          preload="auto"
          onEnded={() => setHeroVideoIndex((i) => (i + 1) % HERO_VIDEOS.length)}
          onError={() => setHeroVideoIndex((i) => (i + 1) % HERO_VIDEOS.length)}
          autoPlay
          ref={heroVideoRef}
        />
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
              <div className="mc-styleCard__icon" aria-hidden="true">
                <StyleIcon name={s.icon} />
              </div>
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
          <MotionSection
            className="mc-section"
            initial={{ opacity: 0, y: 20 }}
            whileInView={{ opacity: 1, y: 0 }}
            viewport={{ once: true, margin: '-60px' }}
            transition={{ duration: 0.6, ease: [0.4, 0, 0.2, 1] }}
          >
            <div className="mc-section__head">
              <h2 className="mc-section__title">Nouveautés</h2>
              <Link className="mc-linkbtn" to="/catalogue">
                Voir tout
              </Link>
            </div>
            {latestProducts.length > 0 ? (
              <div className="mc-grid">
                {latestProducts.map((p, idx) => (
                  <ProductCard key={p.id} product={p} index={idx} />
                ))}
              </div>
            ) : (
              <div className="mc-muted">Aucun produit.</div>
            )}
          </MotionSection>
        </div>
      ) : null}
    </div>
  )
}
