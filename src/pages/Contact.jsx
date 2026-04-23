import { motion } from 'framer-motion'
import { useState } from 'react'

import Notice from '../components/Notice.jsx'
import { createInquiry } from '../lib/api/inquiries.js'
import { isSupabaseConfigured } from '../lib/supabaseClient.js'

const WHATSAPP_NUMBER = '212691567246'

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

export default function Contact() {
  const MotionDiv = motion.div
  const [form, setForm] = useState({ name: '', phone: '', city: '', address: '' })
  const [status, setStatus] = useState('idle')
  const [error, setError] = useState(null)

  async function onSubmit(e) {
    e.preventDefault()
    setError(null)
    const phone = normalizePhone(form.phone)
    if (phone.length !== 10) {
      setError(new Error('Téléphone obligatoire (10 chiffres).'))
      return
    }

    const ok = window.confirm(`Confirmer l'envoi ? WhatsApp va s'ouvrir pour confirmer le message.`)
    if (!ok) return

    let waPopup = null
    waPopup = window.open('about:blank', '_blank', 'noopener,noreferrer')

    setStatus('loading')
    try {
      const data = await createInquiry({
        productId: null,
        name: form.name.trim(),
        email: '',
        phone,
        city: form.city.trim(),
        address: form.address.trim(),
      })
      setStatus('success')
      const lines = [
        'Maison Chrono — Contact',
        form.name.trim() ? `Nom: ${form.name.trim()}` : null,
        `Téléphone: ${phone}`,
        form.city.trim() ? `Ville: ${form.city.trim()}` : null,
        form.address.trim() ? `Adresse: ${form.address.trim()}` : null,
        data?.id ? `Référence: ${data.id}` : null,
        `Site: ${window.location.origin}`,
      ].filter(Boolean)
      const url = createWhatsAppUrl(lines.join('\n'))
      openWhatsAppUrl(url, waPopup)
      setForm({ name: '', phone: '', city: '', address: '' })
    } catch (err) {
      if (waPopup && !waPopup.closed) {
        try {
          waPopup.close?.()
        } catch {
          null
        }
      }
      setError(err)
      setStatus('error')
    }
  }

  return (
    <MotionDiv
      className="mc-stack"
      initial={{ opacity: 0, y: 14 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ duration: 0.6, ease: 'easeOut' }}
    >
      <header className="mc-pagehead">
        <h1 className="mc-pagehead__title">Contact</h1>
        <p className="mc-pagehead__subtitle">Décris ta demande, on te répond rapidement.</p>
      </header>

      {!isSupabaseConfigured() ? (
        <Notice title="Supabase non configuré" tone="danger">
          Configure <span className="mc-code">VITE_SUPABASE_URL</span> et{' '}
          <span className="mc-code">VITE_SUPABASE_ANON_KEY</span> pour activer le formulaire.
        </Notice>
      ) : null}

      <section className="mc-panel">
        <div className="mc-panel__title">Formulaire</div>

        {status === 'success' ? (
          <Notice title="Message envoyé" tone="success">
            Merci. Nous revenons vers vous rapidement.
          </Notice>
        ) : null}

        {status === 'error' ? (
          <Notice title="Envoi impossible" tone="danger">
            {String(error?.message ?? error)}
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

          <label className="mc-field">
            <span className="mc-field__label">Adresse</span>
            <textarea
              className="mc-input mc-input--textarea"
              value={form.address}
              onChange={(e) => setForm((f) => ({ ...f, address: e.target.value }))}
            />
          </label>

          {error && status !== 'error' ? (
            <Notice title="Formulaire" tone="danger">
              {String(error?.message ?? error)}
            </Notice>
          ) : null}

          <button className="mc-btn mc-btn--primary" disabled={status === 'loading'}>
            {status === 'loading' ? 'Envoi…' : 'Envoyer'}
          </button>
        </form>
      </section>
    </MotionDiv>
  )
}
