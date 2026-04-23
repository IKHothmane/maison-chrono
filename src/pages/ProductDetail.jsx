import { motion, AnimatePresence } from 'framer-motion'
import { useEffect, useMemo, useState } from 'react'
import { Link, useParams } from 'react-router-dom'

import Notice from '../components/Notice.jsx'
import ProductCard from '../components/ProductCard.jsx'
import { getProductById, listProducts } from '../lib/api/catalog.js'
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

function isMobileDevice() {
  return /Android|iPhone|iPad|iPod/i.test(navigator.userAgent)
}

function createWhatsAppUrl(text) {
  if (isMobileDevice()) {
    return `https://api.whatsapp.com/send?phone=${WHATSAPP_NUMBER}&text=${encodeURIComponent(text)}`
  }
  return `https://wa.me/${WHATSAPP_NUMBER}?text=${encodeURIComponent(text)}`
}

function openWhatsAppUrl(url, popup) {
  if (popup && !popup.closed) {
    popup.location.href = url
    try {
      popup.focus?.()
    } catch {
      null
    }
    return
  }
  window.location.href = url
}

function normalizePhone(value) {
  return String(value ?? '')
    .replace(/\D/g, '')
    .slice(0, 10)
}

function Spec({ label, value, index = 0 }) {
  if (value === null || value === undefined || value === '') return null
  const MotionDiv = motion.div
  return (
    <MotionDiv
      className="mc-spec"
      initial={{ opacity: 0, x: -12 }}
      animate={{ opacity: 1, x: 0 }}
      transition={{ duration: 0.4, delay: index * 0.08, ease: [0.4, 0, 0.2, 1] }}
    >
      <div className="mc-spec__label">{label}</div>
      <div className="mc-spec__value">{value}</div>
    </MotionDiv>
  )
}

function ProductSkeleton() {
  return (
    <section className="mc-product">
      <div>
        <div className="mc-skeleton" style={{ height: 480, borderRadius: 18 }} />
      </div>
      <div style={{ display: 'grid', gap: 14 }}>
        <div className="mc-skeleton mc-skeleton--text" style={{ width: '40%' }} />
        <div className="mc-skeleton mc-skeleton--title" style={{ width: '75%' }} />
        <div className="mc-skeleton mc-skeleton--text" style={{ width: '30%' }} />
        <div className="mc-skeleton" style={{ height: 120 }} />
        <div className="mc-skeleton" style={{ height: 200 }} />
      </div>
    </section>
  )
}

export default function ProductDetail() {
  const MotionDiv = motion.div
  const MotionSection = motion.section
  const { id } = useParams()
  const [product, setProduct] = useState(null)
  const [error, setError] = useState(null)
  const [loadedId, setLoadedId] = useState(null)
  const [related, setRelated] = useState([])
  const [relatedTitle, setRelatedTitle] = useState('')
  const [relatedError, setRelatedError] = useState(null)

  const [activeImageIndex, setActiveImageIndex] = useState(0)
  const images = useMemo(() => product?.images ?? [], [product])

  useEffect(() => {
    if (images.length <= 1) return
    const id = window.setInterval(() => {
      setActiveImageIndex((i) => (i + 1) % images.length)
    }, 3200)
    return () => window.clearInterval(id)
  }, [images])

  const [form, setForm] = useState({ name: '', phone: '', city: '', address: '' })
  const [submitStatus, setSubmitStatus] = useState('idle')
  const [submitError, setSubmitError] = useState(null)
  const [inquiryId, setInquiryId] = useState(null)
  const [boxType, setBoxType] = useState('simple')

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

  useEffect(() => {
    if (!isSupabaseConfigured()) return
    if (!product?.id) return
    const brandId = product?.brands?.id ?? null
    const categoryId = product?.categories?.id ?? null

    let cancelled = false
    setRelatedError(null)

    async function loadRelated() {
      const strategies = [
        { title: 'Produits similaires', params: brandId && categoryId ? { brandId, categoryId } : null },
        { title: 'Même marque', params: brandId ? { brandId } : null },
        { title: 'Même catégorie', params: categoryId ? { categoryId } : null },
        { title: 'Autres produits', params: {} },
      ].filter((x) => x.params != null)

      let lastError = null
      for (const s of strategies) {
        try {
          const rows = await listProducts(s.params)
          const list = (rows ?? []).filter((p) => p?.id && p.id !== product.id).slice(0, 6)
          if (list.length > 0) {
            if (!cancelled) {
              setRelatedTitle(s.title)
              setRelated(list)
            }
            return
          }
        } catch (e) {
          lastError = e
        }
      }

      if (!cancelled) {
        setRelatedTitle('')
        setRelated([])
        setRelatedError(lastError)
      }
    }

    loadRelated()

    return () => {
      cancelled = true
    }
  }, [product?.id, product?.brands?.id, product?.categories?.id])

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
  const discountPercent = hasDiscount ? Math.round(((compareAt - price) / compareAt) * 100) : null
  const baseDisplayPrice = promo?.finalPrice ?? price
  const baseHasPromo = promo?.finalPrice != null && promo.finalPrice < price
  const priceOld = baseHasPromo ? price : hasDiscount ? compareAt : null
  const boxFee = boxType === 'brand' ? 150 : 0
  const displayPriceNow = baseDisplayPrice + boxFee
  const displayPriceOld = priceOld == null ? null : priceOld + boxFee
  const boxLabel =
    boxType === 'brand'
      ? 'Boîtier original'
      : 'Boîtier normal'
  const boxPriceLabel = boxType === 'brand' ? '+150 DH' : 'Gratuite'

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
        setPromoError(new Error(`Code appliqué, mais aucune réduction n\u2019a été détectée.`))
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

    const phone = normalizePhone(form.phone)
    if (phone.length !== 10) {
      setSubmitError(new Error('Téléphone obligatoire (10 chiffres).'))
      return
    }

    const ok = window.confirm(`Confirmer l'envoi ? WhatsApp va s'ouvrir pour confirmer le message.`)
    if (!ok) return

    let waPopup = null
    waPopup = window.open('about:blank', '_blank', 'noopener,noreferrer')

    setSubmitStatus('loading')
    try {
      const data = await createInquiry({
        productId: product?.id ?? null,
        name: form.name.trim(),
        email: '',
        phone,
        city: form.city.trim(),
        address: form.address.trim(),
      })
      setInquiryId(data?.id ?? null)
      setSubmitStatus('success')
      const productName = product?.name ?? ''
      const productLink = product?.id ? `${window.location.origin}/produit/${product.id}` : window.location.origin
      const lines = [
        'Maison Chrono — Demande',
        productName ? `Produit: ${productName}` : null,
        `Prix montre: ${formatDh(baseDisplayPrice)}`,
        `Boîtier: ${boxLabel} (${boxPriceLabel})`,
        `Total: ${formatDh(displayPriceNow)}`,
        form.name.trim() ? `Nom: ${form.name.trim()}` : null,
        `Téléphone: ${phone}`,
        form.city.trim() ? `Ville: ${form.city.trim()}` : null,
        form.address.trim() ? `Adresse: ${form.address.trim()}` : null,
        data?.id ? `Référence: ${data.id}` : null,
        `Lien: ${productLink}`,
      ].filter(Boolean)
      const url = createWhatsAppUrl(lines.join('\n'))
      openWhatsAppUrl(url, waPopup)
      setForm({ name: '', phone: '', city: '', address: '' })
      setBoxType('simple')
    } catch (err) {
      if (waPopup && !waPopup.closed) {
        try {
          waPopup.close?.()
        } catch {
          null
        }
      }
      setSubmitError(err)
      setSubmitStatus('error')
    }
  }

  const specs = product
    ? [
        { label: 'Référence', value: product.reference },
        { label: 'Boîtier', value: product.material },
        { label: 'Mouvement', value: product.movement },
        { label: 'Étanchéité', value: product.water_resistance },
        { label: 'Diamètre', value: product.diameter ? `${product.diameter} mm` : null },
      ].filter((s) => s.value != null && s.value !== '')
    : []

  return (
    <div className="mc-stack">
      <MotionDiv
        className="mc-breadcrumb"
        initial={{ opacity: 0, x: -12 }}
        animate={{ opacity: 1, x: 0 }}
        transition={{ duration: 0.4 }}
      >
        <Link className="mc-link" to="/catalogue">
          ← Retour au catalogue
        </Link>
      </MotionDiv>

      {!isSupabaseConfigured() ? (
        <Notice title="Supabase non configuré" tone="danger">
          Configure <span className="mc-code">VITE_SUPABASE_URL</span> et{' '}
          <span className="mc-code">VITE_SUPABASE_ANON_KEY</span> pour afficher ce produit.
        </Notice>
      ) : null}

      {status === 'loading' ? <ProductSkeleton /> : null}
      {status === 'error' ? (
        <Notice title="Erreur de chargement" tone="danger">
          {String(error?.message ?? error)}
        </Notice>
      ) : null}
      {status === 'success' && (!product || product.id !== id) ? (
        <div className="mc-muted">Produit introuvable.</div>
      ) : null}

      {product && product.id === id ? (
        <div className="mc-stack">
          <MotionSection
            className="mc-product"
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            transition={{ duration: 0.5 }}
          >
            <MotionDiv
              className="mc-product__gallery"
              initial={{ opacity: 0, x: -20 }}
              animate={{ opacity: 1, x: 0 }}
              transition={{ duration: 0.6, ease: [0.4, 0, 0.2, 1] }}
            >
              <div className="mc-product__image">
                {discountPercent ? (
                  <div className="mc-discountBadge mc-discountBadge--lg">-{discountPercent}%</div>
                ) : null}
                <AnimatePresence mode="wait">
                  {activeImageUrl ? (
                    <MotionDiv
                      key={activeImageUrl}
                      initial={{ opacity: 0 }}
                      animate={{ opacity: 1 }}
                      exit={{ opacity: 0 }}
                      transition={{ duration: 0.4 }}
                      style={{ width: '100%', height: '100%' }}
                    >
                      <img src={activeImageUrl} alt="" className="mc-product__img" />
                    </MotionDiv>
                  ) : (
                    <div className="mc-product__img mc-product__img--placeholder"></div>
                  )}
                </AnimatePresence>
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

            <MotionDiv
              className="mc-product__info"
              initial={{ opacity: 0, x: 20 }}
              animate={{ opacity: 1, x: 0 }}
              transition={{ duration: 0.6, delay: 0.15, ease: [0.4, 0, 0.2, 1] }}
            >
              <div className="mc-product__kicker">
                {product.brands?.name ?? ''}
                {product.brands?.name && product.categories?.name ? ' · ' : ''}
                {product.categories?.name ?? ''}
              </div>
              <h1 className="mc-product__title">{product.name}</h1>
              <div className="mc-product__priceRow">
                <div className="mc-product__price">
                  <div className="mc-priceStack">
                    <div className="mc-priceNow">{formatDh(displayPriceNow)}</div>
                    {displayPriceOld ? <div className="mc-priceOld">{formatDh(displayPriceOld)}</div> : null}
                  </div>
                  <div className="mc-muted">
                    {boxLabel} ({boxPriceLabel})
                  </div>
                </div>
                <span className={`mc-badge${product.in_stock ? '' : ' is-muted'}`}>
                  {product.in_stock ? '✓ Disponible' : 'Sur demande'}
                </span>
              </div>

              <MotionDiv
                className="mc-panel"
                initial={{ opacity: 0, y: 10 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ duration: 0.4, delay: 0.3 }}
              >
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
              </MotionDiv>

              <MotionDiv
                className="mc-panel"
                initial={{ opacity: 0, y: 10 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ duration: 0.4, delay: 0.33 }}
              >
                <div className="mc-panel__title">Boîtier</div>
                <div className="mc-choiceList">
                  <label className="mc-choice">
                    <input
                      type="radio"
                      name="boxType"
                      checked={boxType === 'simple'}
                      onChange={() => setBoxType('simple')}
                    />
                    <div className="mc-choice__main">
                      <span className="mc-choice__title">Boîtier normal</span>
                      <span className="mc-choice__price">Gratuite</span>
                    </div>
                  </label>
                  <label className="mc-choice">
                    <input
                      type="radio"
                      name="boxType"
                      checked={boxType === 'brand'}
                      onChange={() => setBoxType('brand')}
                    />
                    <div className="mc-choice__main">
                      <span className="mc-choice__title">
                        Boîtier original
                      </span>
                      <span className="mc-choice__price">+150 DH</span>
                    </div>
                  </label>
                </div>
              </MotionDiv>

              {product.description ? (
                <MotionDiv
                  initial={{ opacity: 0 }}
                  animate={{ opacity: 1 }}
                  transition={{ delay: 0.35 }}
                >
                  <p className="mc-product__desc">{product.description}</p>
                </MotionDiv>
              ) : null}

              {specs.length > 0 ? (
                <MotionDiv
                  className="mc-panel"
                  initial={{ opacity: 0, y: 10 }}
                  animate={{ opacity: 1, y: 0 }}
                  transition={{ duration: 0.4, delay: 0.4 }}
                >
                  <div className="mc-panel__title">Spécifications</div>
                  <div className="mc-specs">
                    {specs.map((s, i) => (
                      <Spec key={s.label} label={s.label} value={s.value} index={i} />
                    ))}
                  </div>
                </MotionDiv>
              ) : null}

              <MotionDiv
                className="mc-panel"
                initial={{ opacity: 0, y: 10 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ duration: 0.4, delay: 0.5 }}
              >
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
                      />
                    </label>
                    <label className="mc-field">
                      <span className="mc-field__label">Ville</span>
                      <input
                        className="mc-input"
                        value={form.city}
                        onChange={(e) => setForm((f) => ({ ...f, city: e.target.value }))}
                      />
                    </label>
                  </div>

                  <label className="mc-field">
                    <span className="mc-field__label">Téléphone</span>
                    <input
                      className="mc-input"
                      type="tel"
                      inputMode="numeric"
                      maxLength={10}
                      pattern="[0-9]{10}"
                      value={form.phone}
                      onChange={(e) => setForm((f) => ({ ...f, phone: normalizePhone(e.target.value) }))}
                      required
                    />
                  </label>

                  <div className="mc-form__row">
                    <label className="mc-field">
                      <span className="mc-field__label">Adresse</span>
                      <input
                        className="mc-input"
                        value={form.address}
                        onChange={(e) => setForm((f) => ({ ...f, address: e.target.value }))}
                      />
                    </label>
                  </div>

                  {submitError && submitStatus !== 'error' ? (
                    <Notice title="Formulaire" tone="danger">
                      {String(submitError?.message ?? submitError)}
                    </Notice>
                  ) : null}

                  <button className="mc-btn mc-btn--primary" disabled={submitStatus === 'loading'}>
                    {submitStatus === 'loading' ? 'Envoi…' : 'Envoyer la demande'}
                  </button>
                </form>
              </MotionDiv>
            </MotionDiv>
          </MotionSection>

          {relatedError ? (
            <Notice title="Produits similaires indisponibles" tone="danger">
              {String(relatedError?.message ?? relatedError)}
            </Notice>
          ) : null}
          {related.length > 0 ? (
            <section className="mc-section">
              <div className="mc-section__head">
                <h2 className="mc-section__title">{relatedTitle || 'Produits similaires'}</h2>
              </div>
              <div className="mc-grid mc-grid--catalog">
                {related.map((p, idx) => (
                  <ProductCard key={p.id} product={p} index={idx} />
                ))}
              </div>
            </section>
          ) : !relatedError ? (
            <div className="mc-muted">Aucun autre produit pour le moment.</div>
          ) : null}
        </div>
      ) : null}
    </div>
  )
}
