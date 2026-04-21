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
const DEBUG_LOG = SHOW_DEBUG_UI

export default function Reels() {
  const [status, setStatus] = useState(() => (isSupabaseConfigured() ? 'loading' : 'idle'))
  const [error, setError] = useState(null)
  const [items, setItems] = useState([])
  const [debugInfo, setDebugInfo] = useState({})
  const containerRef = useRef(null)
  const videoRefs = useRef(new Map())

  useEffect(() => {
    if (!DEBUG_LOG) return
    console.log('[MaisonChrono][Reels] mount', { supabaseConfigured: isSupabaseConfigured() })
  }, [])

  useEffect(() => {
    if (!isSupabaseConfigured()) return
    let cancelled = false
    listReels()
      .then((rows) => {
        if (cancelled) return
        if (DEBUG_LOG) console.log('[MaisonChrono][Reels] ok', rows.length)
        if (DEBUG_LOG) {
          console.log('[MaisonChrono][Reels] urls sample', rows.slice(0, 5).map((r) => r.public_url))
        }
        setItems(rows)
        setError(null)
        setStatus('success')
      })
      .catch((e) => {
        if (cancelled) return
        if (DEBUG_LOG) console.log('[MaisonChrono][Reels] error', e)
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
    if (!DEBUG_LOG) return
    console.log('[MaisonChrono][Reels] render', { status, safeCount: safeItems.length })
  }, [status, safeItems.length])

  useEffect(() => {
    const root = containerRef.current
    if (!root) return

    const observer = new IntersectionObserver(
      (entries) => {
        for (const entry of entries) {
          const el = entry.target
          const id = el?.dataset?.reelId
          if (!id) continue
          const video = videoRefs.current.get(id)
          if (!video) continue
          if (entry.isIntersecting && entry.intersectionRatio >= 0.65) {
            video.play().catch(() => {})
          } else {
            video.pause()
          }
        }
      },
      { root, threshold: [0, 0.65, 1] },
    )

    for (const section of root.querySelectorAll('[data-reel-id]')) {
      observer.observe(section)
    }

    return () => observer.disconnect()
  }, [safeItems])

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
            return (
              <section key={id} className="mc-reel" data-reel-id={id}>
                <video
                  className="mc-reel__video"
                  src={it.public_url}
                  muted
                  playsInline
                  loop
                  preload="metadata"
                  onLoadedMetadata={(e) => {
                    if (!DEBUG_LOG) return
                    const v = e.currentTarget
                    console.log('[MaisonChrono][Reels] video metadata', {
                      id,
                      duration: v.duration,
                      w: v.videoWidth,
                      h: v.videoHeight,
                    })
                    if (SHOW_DEBUG_UI) {
                      setDebugInfo((prev) => ({
                        ...prev,
                        [id]: {
                          ...(prev[id] ?? {}),
                          meta: { duration: v.duration, w: v.videoWidth, h: v.videoHeight },
                        },
                      }))
                    }
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
                    if (DEBUG_LOG) console.log('[MaisonChrono][Reels] video error', payload)
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
                  onClick={(e) => {
                    const v = e.currentTarget
                    if (v.paused) v.play().catch(() => {})
                    else v.pause()
                  }}
                />
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
