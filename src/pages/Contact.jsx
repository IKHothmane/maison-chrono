import { motion } from 'framer-motion'
import { useState } from 'react'

import Notice from '../components/Notice.jsx'
import { createInquiry } from '../lib/api/inquiries.js'
import { isSupabaseConfigured } from '../lib/supabaseClient.js'

const WHATSAPP_NUMBER = '212691567246'

function openWhatsApp(text) {
  const url = `https://wa.me/${WHATSAPP_NUMBER}?text=${encodeURIComponent(text)}`
  window.open(url, '_blank', 'noopener,noreferrer')
}

export default function Contact() {
  const MotionDiv = motion.div
  const [form, setForm] = useState({ name: '', email: '', phone: '', message: '' })
  const [status, setStatus] = useState('idle')
  const [error, setError] = useState(null)

  async function onSubmit(e) {
    e.preventDefault()
    setError(null)
    if (!form.name.trim() || !form.phone.trim() || !form.message.trim()) {
      setError(new Error('Nom, téléphone et message sont obligatoires.'))
      return
    }

    const ok = window.confirm('Confirmer l’envoi ? WhatsApp va s’ouvrir pour confirmer le message.')
    if (!ok) return

    setStatus('loading')
    try {
      const data = await createInquiry({
        productId: null,
        name: form.name.trim(),
        email: form.email.trim(),
        phone: form.phone,
        message: form.message.trim(),
      })
      setStatus('success')
      const lines = [
        'Demande Maison Chrono',
        `Nom: ${form.name.trim()}`,
        `Téléphone: ${form.phone.trim()}`,
        form.email.trim() ? `Email: ${form.email.trim()}` : null,
        `Message: ${form.message.trim()}`,
        data?.id ? `Référence: ${data.id}` : null,
        `Site: ${window.location.origin}`,
      ].filter(Boolean)
      openWhatsApp(lines.join('\n'))
      setForm({ name: '', email: '', phone: '', message: '' })
    } catch (err) {
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
              rows={6}
              required
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
