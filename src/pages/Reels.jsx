import { useEffect, useMemo, useRef, useState } from 'react'
import { Link } from 'react-router-dom'

import Notice from '../components/Notice.jsx'
import { listReels } from '../lib/api/videos.js'
import { isSupabaseConfigured } from '../lib/supabaseClient.js'

const DEBUG = Boolean(import.meta?.env?.DEV) || String(import.meta?.env?.VITE_DEBUG ?? '') === '1'
const SHOW_DEBUG_UI =
  DEBUG ||
  String(import.meta?.env?.VITE_DEBUG_UI ?? '') === '1' ||
  (typeof window !== 'undefined' && new URLSearchParams(window.location.search).get('debug') === '1') ||
  (typeof window !== 'undefined' && window.localStorage?.getItem('mc_debug_ui') === '1')

export default function Reels() {
  const [status, setStatus] = useState(() => (isSupabaseConfigured() ? 'loading' : 'idle'))
  const [error, setError] = useState(null)
  const [items, setItems] = useState([])
  const [debugInfo, setDebugInfo] = useState({})
  const [mutedById, setMutedById] = useState({})
  const [isDesktop, setIsDesktop] = useState(() => {
    if (typeof window === 'undefined') return false
    return window.matchMedia?.('(hover: hover) and (pointer: fine)')?.matches ?? false
  })
  const containerRef = useRef(null)
  const videoRefs = useRef(new Map())

  useEffect(() => {
    if (typeof window === 'undefined' || !window.matchMedia) return
    const mq = window.matchMedia('(hover: hover) and (pointer: fine)')
    function onChange(e) {
      setIsDesktop(Boolean(e.matches))
    }
    if (typeof mq.addEventListener === 'function') mq.addEventListener('change', onChange)
    else if (typeof mq.addListener === 'function') mq.addListener(onChange)
    return () => {
      if (typeof mq.removeEventListener === 'function') mq.removeEventListener('change', onChange)
      else if (typeof mq.removeListener === 'function') mq.removeListener(onChange)
    }
  }, [])

  useEffect(() => {
    if (!isSupabaseConfigured()) return
    let cancelled = false
    listReels()
      .then((rows) => {
        if (cancelled) return
        setItems(rows)
        setError(null)
        setStatus('success')
      })
      .catch((e) => {
        if (cancelled) return
        setError(e)
        setStatus('error')
      })
    return () => {
      cancelled = true
    }
  }, [])

  const safeItems = useMemo(() => items.filter((x) => x?.public_url), [items])

  useEffect(() => {
    if (!SHOW_DEBUG_UI) return
    let cancelled = false
    const sample = safeItems.slice(0, 6)
    Promise.all(
      sample.map(async (it) => {
        const id = String(it.id ?? it.public_url)
        const url = it.public_url
        try {
          const res = await fetch(url, {
            method: 'GET',
            headers: { Range: 'bytes=0-0' },
            cache: 'no-store',
          })
          return {
            id,
            head: {
              status: res.status,
              contentType: res.headers.get('content-type'),
              acceptRanges: res.headers.get('accept-ranges'),
            },
          }
        } catch (e) {
          return { id, head: { error: String(e?.message ?? e) } }
        }
      }),
    ).then((rows) => {
      if (cancelled) return
      setDebugInfo((prev) => {
        const next = { ...prev }
        for (const r of rows) next[r.id] = { ...(next[r.id] ?? {}), head: r.head }
        return next
      })
    })
    return () => {
      cancelled = true
    }
  }, [safeItems])

  useEffect(() => {
    const root = containerRef.current
    if (!root) return

    const observerRoot = isDesktop ? null : root
    const thresholds = isDesktop ? [0, 0.1] : [0, 0.65, 1]

    const observer = new IntersectionObserver(
      (entries) => {
        for (const entry of entries) {
          const el = entry.target
          const id = el?.dataset?.reelId
          if (!id) continue
          const video = videoRefs.current.get(id)
          if (!video) continue
          if (isDesktop) {
            if (!entry.isIntersecting || entry.intersectionRatio < 0.1) video.pause()
            continue
          }
          if (entry.isIntersecting && entry.intersectionRatio >= 0.65) video.play().catch(() => {})
          else video.pause()
        }
      },
      { root: observerRoot, threshold: thresholds },
    )

    for (const section of root.querySelectorAll('[data-reel-id]')) {
      observer.observe(section)
    }

    return () => observer.disconnect()
  }, [safeItems, isDesktop])

  function toggleMute(id) {
    setMutedById((prev) => {
      const next = { ...prev }
      const defaultMuted = isDesktop ? false : true
      next[id] = !(prev[id] ?? defaultMuted)
      return next
    })
  }

  return (
    <div className="mc-reelsWrap">
      {!isSupabaseConfigured() ? (
        <Notice title="Supabase non configuré" tone="danger">
          Configure <span className="mc-code">VITE_SUPABASE_URL</span> et{' '}
          <span className="mc-code">VITE_SUPABASE_ANON_KEY</span> pour activer les vidéos.
        </Notice>
      ) : null}

      {status === 'loading' ? <div className="mc-muted">Chargement…</div> : null}
      {status === 'error' ? (
        <Notice title="Erreur" tone="danger">
          {String(error?.message ?? error)}
        </Notice>
      ) : null}

      {status === 'success' && safeItems.length === 0 ? (
        <div className="mc-muted">Aucune vidéo.</div>
      ) : null}

      {safeItems.length > 0 ? (
        <div className="mc-reels" ref={containerRef} aria-label="Vidéos">
          {safeItems.map((it) => {
            const id = String(it.id ?? it.public_url)
            const productId = it.product_id ?? it.products?.id ?? null
            const productName = it.products?.name ?? ''
            const muted = mutedById[id] ?? (isDesktop ? false : true)
            return (
              <section key={id} className="mc-reel" data-reel-id={id}>
                <div className="mc-reel__frame">
                  <video
                    className="mc-reel__video"
                    src={it.public_url}
                    muted={muted}
                    playsInline
                    loop
                    preload="metadata"
                    onLoadedMetadata={(e) => {
                      if (!SHOW_DEBUG_UI) return
                      const v = e.currentTarget
                      setDebugInfo((prev) => ({
                        ...prev,
                        [id]: {
                          ...(prev[id] ?? {}),
                          meta: { duration: v.duration, w: v.videoWidth, h: v.videoHeight },
                        },
                      }))
                    }}
                    onError={(e) => {
                      const v = e.currentTarget
                      const payload = {
                        id,
                        src: v.currentSrc,
                        code: v.error?.code ?? null,
                        networkState: v.networkState,
                        readyState: v.readyState,
                      }
                      if (SHOW_DEBUG_UI) {
                        setDebugInfo((prev) => ({
                          ...prev,
                          [id]: {
                            ...(prev[id] ?? {}),
                            error: payload,
                          },
                        }))
                      }
                    }}
                    ref={(node) => {
                      if (!node) videoRefs.current.delete(id)
                      else videoRefs.current.set(id, node)
                    }}
                    onMouseEnter={
                      isDesktop
                        ? (e) => {
                            e.currentTarget.play().catch(() => {
                              setMutedById((prev) => ({ ...prev, [id]: true }))
                              e.currentTarget.muted = true
                              e.currentTarget.play().catch(() => {})
                            })
                          }
                        : undefined
                    }
                    onMouseLeave={
                      isDesktop
                        ? (e) => {
                            e.currentTarget.pause()
                          }
                        : undefined
                    }
                    onFocus={
                      isDesktop
                        ? (e) => {
                            e.currentTarget.play().catch(() => {})
                          }
                        : undefined
                    }
                    onBlur={
                      isDesktop
                        ? (e) => {
                            e.currentTarget.pause()
                          }
                        : undefined
                    }
                    onClick={(e) => {
                      const v = e.currentTarget
                      if (v.paused) v.play().catch(() => {})
                      else v.pause()
                    }}
                  />
                </div>
                <button
                  className="mc-reel__soundBtn"
                  type="button"
                  aria-label={muted ? 'Activer le son' : 'Couper le son'}
                  aria-pressed={!muted}
                  onClick={(e) => {
                    e.preventDefault()
                    e.stopPropagation()
                    toggleMute(id)
                  }}
                >
                  {muted ? (
                    <svg width="18" height="18" viewBox="0 0 20 20" fill="none" aria-hidden="true">
                      <path
                        d="M3.5 8.2v3.6h2.6l3.4 2.7V5.5L6.1 8.2H3.5Z"
                        stroke="currentColor"
                        strokeWidth="1.6"
                        strokeLinejoin="round"
                      />
                      <path
                        d="M12.8 7.2 16.8 13.2M16.8 7.2 12.8 13.2"
                        stroke="currentColor"
                        strokeWidth="1.6"
                        strokeLinecap="round"
                      />
                    </svg>
                  ) : (
                    <svg width="18" height="18" viewBox="0 0 20 20" fill="none" aria-hidden="true">
                      <path
                        d="M3.5 8.2v3.6h2.6l3.4 2.7V5.5L6.1 8.2H3.5Z"
                        stroke="currentColor"
                        strokeWidth="1.6"
                        strokeLinejoin="round"
                      />
                      <path
                        d="M13.3 6.7a4.6 4.6 0 0 1 0 6.6"
                        stroke="currentColor"
                        strokeWidth="1.6"
                        strokeLinecap="round"
                      />
                    </svg>
                  )}
                </button>
                <div className="mc-reel__meta">
                  {productId ? (
                    <Link className="mc-reel__link" to={`/produit/${productId}`}>
                      {productName ? productName : 'Voir le produit'}
                    </Link>
                  ) : (
                    <div className="mc-reel__link">{productName || 'Maison Chrono'}</div>
                  )}
                </div>
                {SHOW_DEBUG_UI ? (
                  <div className="mc-reel__debug">
                    <div className="mc-reel__debugLabel">URL</div>
                    <div className="mc-reel__debugValue">{it.public_url}</div>
                    {debugInfo[id]?.head ? (
                      <div className="mc-reel__debugValue">
                        {debugInfo[id]?.head?.error
                          ? `Fetch: ${debugInfo[id].head.error}`
                          : `Fetch: ${debugInfo[id].head.status} · ${debugInfo[id].head.contentType ?? 'no content-type'} · ${debugInfo[id].head.acceptRanges ?? 'no accept-ranges'}`}
                      </div>
                    ) : null}
                    {debugInfo[id]?.meta ? (
                      <div className="mc-reel__debugValue">
                        Meta: {Math.round(debugInfo[id].meta.w)}×{Math.round(debugInfo[id].meta.h)} ·{' '}
                        {Number.isFinite(debugInfo[id].meta.duration)
                          ? `${debugInfo[id].meta.duration.toFixed(2)}s`
                          : 'durée inconnue'}
                      </div>
                    ) : null}
                    {debugInfo[id]?.error ? (
                      <div className="mc-reel__debugValue">
                        VideoError: code={debugInfo[id].error.code ?? 'null'} · ready=
                        {debugInfo[id].error.readyState} · net={debugInfo[id].error.networkState}
                      </div>
                    ) : null}
                  </div>
                ) : null}
              </section>
            )
          })}
        </div>
      ) : null}
    </div>
  )
}
