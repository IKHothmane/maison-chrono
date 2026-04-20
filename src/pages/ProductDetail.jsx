import { motion } from 'framer-motion'
import { useEffect, useMemo, useState } from 'react'
import { Link, useParams } from 'react-router-dom'

import Notice from '../components/Notice.jsx'
import { getProductById } from '../lib/api/catalog.js'
import { createInquiry } from '../lib/api/inquiries.js'
import { isSupabaseConfigured, supabase } from '../lib/supabaseClient.js'

const numberFormatter = new Intl.NumberFormat('fr-FR', {
  maximumFractionDigits: 0,
})

const WHATSAPP_NUMBER = '212691567246'

function formatDh(value) {
  const n = typeof value === 'number' ? value : Number(value)
  const safe = Number.isFinite(n) ? n : 0
  return `${numberFormatter.format(safe)} DH`
}

function openWhatsApp(text) {
  const url = `https://wa.me/${WHATSAPP_NUMBER}?text=${encodeURIComponent(text)}`
  window.open(url, '_blank', 'noopener,noreferrer')
}

function Spec({ label, value }) {
  if (value === null || value === undefined || value === '') return null
  return (
    <div className="mc-spec">
      <div className="mc-spec__label">{label}</div>
      <div className="mc-spec__value">{value}</div>
    </div>
  )
}

export default function ProductDetail() {
  const MotionDiv = motion.div
  const { id } = useParams()
  const [product, setProduct] = useState(null)
  const [error, setError] = useState(null)
  const [loadedId, setLoadedId] = useState(null)

  const [activeImageIndex, setActiveImageIndex] = useState(0)
  const images = useMemo(() => product?.images ?? [], [product])

  useEffect(() => {
    if (images.length <= 1) return
    const id = window.setInterval(() => {
      setActiveImageIndex((i) => (i + 1) % images.length)
    }, 3200)
    return () => window.clearInterval(id)
  }, [images])

  const [form, setForm] = useState({ name: '', email: '', phone: '', message: '' })
  const [submitStatus, setSubmitStatus] = useState('idle')
  const [submitError, setSubmitError] = useState(null)
  const [inquiryId, setInquiryId] = useState(null)

  const [promoCode, setPromoCode] = useState('')
  const [promoStatus, setPromoStatus] = useState('idle')
  const [promoError, setPromoError] = useState(null)
  const [promo, setPromo] = useState(null)

  useEffect(() => {
    if (!isSupabaseConfigured()) return
    if (!id) return

    let cancelled = false

    getProductById(id)
      .then((data) => {
        if (cancelled) return
        setProduct(data)
        setError(null)
        setLoadedId(id)
        setActiveImageIndex(0)
      })
      .catch((err) => {
        if (cancelled) return
        setError(err)
        setLoadedId(id)
      })

    return () => {
      cancelled = true
    }
  }, [id])

  const status = !isSupabaseConfigured()
    ? 'idle'
    : loadedId === id
      ? error
        ? 'error'
        : 'success'
      : 'loading'

  const activeImageUrl = images[activeImageIndex] ?? images[0] ?? null
  const price = Number(product?.price ?? 0)
  const compareAt = product?.compare_at_price == null ? null : Number(product.compare_at_price)
  const hasDiscount = Number.isFinite(price) && Number.isFinite(compareAt) && compareAt > price
  const baseDisplayPrice = promo?.finalPrice ?? price
  const baseHasPromo = promo?.finalPrice != null && promo.finalPrice < price
  const priceOld = baseHasPromo ? price : hasDiscount ? compareAt : null

  async function applyPromo(e) {
    e.preventDefault()
    setPromoError(null)
    setPromo(null)

    const code = promoCode.trim().toUpperCase()
    if (!code) return
    if (!supabase) return

    setPromoStatus('loading')
    try {
      const { data, error: promoErr } = await supabase.rpc('redeem_promo', {
        p_code: code,
        p_product_id: product?.id ?? null,
        p_price: Number(price),
      })
      if (promoErr) throw promoErr
      const row = Array.isArray(data) ? data[0] : data
      if (!row) throw new Error('Code promo invalide.')

      const finalPrice = row.final_price
      setPromo({
        code: row.code,
        finalPrice,
        discountPercent: row.discount_percent ?? null,
        discountAmount: row.discount_amount ?? null,
      })
      if (finalPrice == null || Number(finalPrice) >= Number(price)) {
        setPromoError(new Error('Code appliqué, mais aucune réduction n’a été détectée.'))
      }
      setPromoStatus('success')
    } catch (err) {
      const msg = String(err?.message ?? err)
      const lower = msg.toLowerCase()
      if (err?.code === '42P01' || err?.code === '42883' || err?.code === 'PGRST202') {
        setPromoError(new Error('Codes promo non configurés pour le moment.'))
      } else if (err?.code === '42501' || lower.includes('permission denied')) {
        setPromoError(
          new Error(
            'Codes promo non autorisés (permissions Supabase). Il faut activer la fonction redeem_promo et donner GRANT EXECUTE à anon/authenticated.',
          ),
        )
      } else if (err?.code === 'P0001') {
        setPromoError(new Error(msg))
      } else {
        setPromoError(err)
      }
      setPromoStatus('error')
    }
  }


  async function onSubmit(e) {
    e.preventDefault()
    setSubmitError(null)

    if (!form.name.trim() || !form.phone.trim() || !form.message.trim()) {
      setSubmitError(new Error('Nom, téléphone et message sont obligatoires.'))
      return
    }

    const ok = window.confirm('Confirmer l’envoi ? WhatsApp va s’ouvrir pour confirmer le message.')
    if (!ok) return

    setSubmitStatus('loading')
    try {
      const data = await createInquiry({
        productId: product?.id ?? null,
        name: form.name.trim(),
        email: form.email.trim(),
        phone: form.phone,
        message: form.message.trim(),
      })
      setInquiryId(data?.id ?? null)
      setSubmitStatus('success')
      const productName = product?.name ?? ''
      const productLink = product?.id ? `${window.location.origin}/produit/${product.id}` : window.location.origin
      const lines = [
        'Demande Maison Chrono',
        productName ? `Produit: ${productName}` : null,
        `Nom: ${form.name.trim()}`,
        `Téléphone: ${form.phone.trim()}`,
        form.email.trim() ? `Email: ${form.email.trim()}` : null,
        `Message: ${form.message.trim()}`,
        data?.id ? `Référence: ${data.id}` : null,
        `Lien: ${productLink}`,
      ].filter(Boolean)
      openWhatsApp(lines.join('\n'))
      setForm({ name: '', email: '', phone: '', message: '' })
    } catch (err) {
      setSubmitError(err)
      setSubmitStatus('error')
    }
  }

  return (
    <div className="mc-stack">
      <div className="mc-breadcrumb">
        <Link className="mc-link" to="/catalogue">
          ← Retour au catalogue
        </Link>
      </div>

      {!isSupabaseConfigured() ? (
        <Notice title="Supabase non configuré" tone="danger">
          Configure <span className="mc-code">VITE_SUPABASE_URL</span> et{' '}
          <span className="mc-code">VITE_SUPABASE_ANON_KEY</span> pour afficher ce produit.
        </Notice>
      ) : null}

      {status === 'loading' ? <div className="mc-muted">Chargement…</div> : null}
      {status === 'error' ? (
        <Notice title="Erreur de chargement" tone="danger">
          {String(error?.message ?? error)}
        </Notice>
      ) : null}
      {status === 'success' && (!product || product.id !== id) ? (
        <div className="mc-muted">Produit introuvable.</div>
      ) : null}

      {product && product.id === id ? (
        <section className="mc-product">
          <MotionDiv
            className="mc-product__gallery"
            initial={{ opacity: 0, y: 14 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.6, ease: 'easeOut' }}
          >
            <div className="mc-product__image">
              {activeImageUrl ? (
                <img src={activeImageUrl} alt="" className="mc-product__img" />
              ) : (
                <div className="mc-product__img mc-product__img--placeholder"></div>
              )}
            </div>
            {images.length > 1 ? (
              <div className="mc-product__thumbs" role="tablist" aria-label="Images produit">
                {images.map((url, idx) => (
                  <button
                    key={`${url}-${idx}`}
                    type="button"
                    className={`mc-thumb${idx === activeImageIndex ? ' is-active' : ''}`}
                    onClick={() => setActiveImageIndex(idx)}
                    aria-label={`Image ${idx + 1}`}
                  >
                    <img src={url} alt="" loading="lazy" />
                  </button>
                ))}
              </div>
            ) : null}
          </MotionDiv>

          <div className="mc-product__info">
            <div className="mc-product__kicker">
              {product.brands?.name ?? ''}
              {product.brands?.name && product.categories?.name ? ' · ' : ''}
              {product.categories?.name ?? ''}
            </div>
            <h1 className="mc-product__title">{product.name}</h1>
            <div className="mc-product__priceRow">
              <div className="mc-product__price">
                <div className="mc-priceStack">
                  <div className="mc-priceNow">{formatDh(baseDisplayPrice)}</div>
                  {priceOld ? <div className="mc-priceOld">{formatDh(priceOld)}</div> : null}
                </div>
              </div>
              <span className={`mc-badge${product.in_stock ? '' : ' is-muted'}`}>
                {product.in_stock ? 'Disponible' : 'Sur demande'}
              </span>
            </div>

            <div className="mc-panel">
              <div className="mc-panel__title">Code promo</div>
              <form className="mc-form" onSubmit={applyPromo}>
                <div className="mc-form__row">
                  <label className="mc-field">
                    <span className="mc-field__label">Code</span>
                    <input
                      className="mc-input"
                      value={promoCode}
                      onChange={(e) => setPromoCode(e.target.value)}
                      placeholder="EX: MAISON10"
                    />
                  </label>
                  <button className="mc-btn mc-btn--primary" disabled={promoStatus === 'loading'}>
                    {promoStatus === 'loading' ? 'Application…' : 'Appliquer'}
                  </button>
                </div>
                {promoStatus === 'success' && promo ? (
                  <Notice title="Code appliqué" tone="success">
                    Code <span className="mc-code">{promo.code}</span> activé.
                  </Notice>
                ) : null}
                {promoStatus === 'error' ? (
                  <Notice title="Code promo" tone="danger">
                    {String(promoError?.message ?? promoError)}
                  </Notice>
                ) : null}
              </form>
            </div>

            {product.description ? <p className="mc-product__desc">{product.description}</p> : null}

            <div className="mc-panel">
              <div className="mc-panel__title">Spécifications</div>
              <div className="mc-specs">
                <Spec label="Référence" value={product.reference} />
                <Spec label="Boîtier" value={product.material} />
                <Spec label="Mouvement" value={product.movement} />
                <Spec label="Étanchéité" value={product.water_resistance} />
                <Spec
                  label="Diamètre"
                  value={product.diameter ? `${product.diameter} mm` : null}
                />
              </div>
            </div>

            <div className="mc-panel">
              <div className="mc-panel__title">Demander un renseignement</div>

              {submitStatus === 'success' ? (
                <Notice title="Demande envoyée" tone="success">
                  Nous revenons vers vous rapidement.
                  {inquiryId ? (
                    <div className="mc-muted">
                      Référence demande : <span className="mc-code">{inquiryId}</span>
                    </div>
                  ) : null}
                </Notice>
              ) : null}

              {submitStatus === 'error' ? (
                <Notice title="Envoi impossible" tone="danger">
                  {String(submitError?.message ?? submitError)}
                </Notice>
              ) : null}

              <form className="mc-form" onSubmit={onSubmit}>
                <div className="mc-form__row">
                  <label className="mc-field">
                    <span className="mc-field__label">Nom</span>
                    <input
                      className="mc-input"
                      value={form.name}
                      onChange={(e) => setForm((f) => ({ ...f, name: e.target.value }))}
                      required
                    />
                  </label>
                  <label className="mc-field">
                    <span className="mc-field__label">Email</span>
                    <input
                      className="mc-input"
                      type="email"
                      value={form.email}
                      onChange={(e) => setForm((f) => ({ ...f, email: e.target.value }))}
                    />
                  </label>
                </div>

                <label className="mc-field">
                  <span className="mc-field__label">Téléphone</span>
                  <input
                    className="mc-input"
                    type="tel"
                    inputMode="tel"
                    value={form.phone}
                    onChange={(e) => setForm((f) => ({ ...f, phone: e.target.value }))}
                    required
                  />
                </label>

                <label className="mc-field">
                  <span className="mc-field__label">Message</span>
                  <textarea
                    className="mc-input mc-input--textarea"
                    value={form.message}
                    onChange={(e) => setForm((f) => ({ ...f, message: e.target.value }))}
                    rows={5}
                    required
                  />
                </label>

                {submitError && submitStatus !== 'error' ? (
                  <Notice title="Formulaire" tone="danger">
                    {String(submitError?.message ?? submitError)}
                  </Notice>
                ) : null}

                <button className="mc-btn mc-btn--primary" disabled={submitStatus === 'loading'}>
                  {submitStatus === 'loading' ? 'Envoi…' : 'Envoyer'}
                </button>
              </form>
            </div>
          </div>
        </section>
      ) : null}
    </div>
  )
}

