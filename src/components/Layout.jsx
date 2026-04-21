import { useEffect, useMemo, useRef, useState } from 'react'
import { NavLink, useLocation, useNavigate } from 'react-router-dom'
import { motion, AnimatePresence } from 'framer-motion'

import deliveryIcon from '../assets/free-shipping-icon.svg'
import giftIcon from '../assets/gift-box-icon.svg'
import logoImg from '../assets/logo.jpg'
import payIcon from '../assets/pay-money-icon.svg'
import returnsIcon from '../assets/delivery-hand-package-icon.svg'

function NavItem({ to, children }) {
  return (
    <NavLink to={to} className={({ isActive }) => `mc-nav__link${isActive ? ' is-active' : ''}`}>
      {children}
    </NavLink>
  )
}

const MENU_LINKS = [
  { to: '/', label: 'Accueil' },
  { to: '/catalogue', label: 'Catalogue' },
  { to: '/reels', label: 'Vidéos' },
  { to: '/a-propos', label: 'À propos' },
  { to: '/contact', label: 'Contact' },
]

export default function Layout({ children }) {
  const navigate = useNavigate()
  const location = useLocation()
  const searchRef = useRef(null)
  const newsletterRef = useRef(null)
  const [isSearchOpen, setIsSearchOpen] = useState(false)
  const urlQuery = useMemo(() => {
    if (!(location.pathname === '/' || location.pathname.startsWith('/catalogue'))) return ''
    const params = new URLSearchParams(location.search)
    return params.get('q') ?? ''
  }, [location.pathname, location.search])

  useEffect(() => {
    if (!isSearchOpen) return
    const t = window.setTimeout(() => {
      searchRef.current?.focus?.()
      searchRef.current?.select?.()
    }, 0)
    return () => window.clearTimeout(t)
  }, [isSearchOpen])

  useEffect(() => {
    if (!isSearchOpen) return
    function onKeyDown(e) {
      if (e.key === 'Escape') setIsSearchOpen(false)
    }
    window.addEventListener('keydown', onKeyDown)
    return () => window.removeEventListener('keydown', onKeyDown)
  }, [isSearchOpen])

  function submitSearch(e) {
    e.preventDefault()
    const q = String(searchRef.current?.value ?? '').trim()
    navigate(q ? `/catalogue?q=${encodeURIComponent(q)}` : '/catalogue')
    setIsSearchOpen(false)
  }

  function submitNewsletter(e) {
    e.preventDefault()
    const email = String(newsletterRef.current?.value ?? '').trim()
    if (!email) return
    const url = `https://wa.me/212691567246?text=${encodeURIComponent(`Newsletter: ${email}`)}`
    window.open(url, '_blank', 'noopener,noreferrer')
    if (newsletterRef.current) newsletterRef.current.value = ''
  }

  const MotionDiv = motion.div

  return (
    <div className="mc-app">
      <header className="mc-header">
        <div className="mc-topbar">
          <div className="mc-container mc-topbar__inner">
            <div className="mc-topbar__msg">✦ Livraison offerte aujourd'hui · Retours 30 jours ✦</div>
          </div>
        </div>

        <div className="mc-container mc-header__main">
          <NavLink to="/" className="mc-brand" aria-label="Maison Chrono">
            <span className="mc-brand__mark" aria-hidden="true">
              <img src={logoImg} alt="" className="mc-brand__logo" />
            </span>
            <span className="mc-brand__text">
              <span className="mc-brand__name">Maison Chrono</span>
              <span className="mc-brand__tag">Montres d'exception</span>
            </span>
          </NavLink>

          <div className="mc-actions" aria-label="Actions">
            <button
              className="mc-action"
              type="button"
              aria-label="Rechercher"
              onClick={() => setIsSearchOpen(true)}
            >
              <svg width="18" height="18" viewBox="0 0 20 20" fill="none" aria-hidden="true">
                <path
                  d="M13.58 13.58 18 18m-4.42-4.42A7 7 0 1 0 3.68 3.68a7 7 0 0 0 9.9 9.9Z"
                  stroke="currentColor"
                  strokeWidth="1.6"
                  strokeLinecap="round"
                />
              </svg>
            </button>
            <NavLink className="mc-action" to="/contact" aria-label="Compte">
              <svg width="18" height="18" viewBox="0 0 20 20" fill="none" aria-hidden="true">
                <path
                  d="M10 10.2a3.7 3.7 0 1 0 0-7.4 3.7 3.7 0 0 0 0 7.4ZM3.4 18c.9-3.2 3.4-5 6.6-5s5.7 1.8 6.6 5"
                  stroke="currentColor"
                  strokeWidth="1.6"
                  strokeLinecap="round"
                />
              </svg>
            </NavLink>
            <button className="mc-action" type="button" aria-label="Favoris">
              <svg width="18" height="18" viewBox="0 0 20 20" fill="none" aria-hidden="true">
                <path
                  d="M10 17.2s-6.6-4.1-8-8.1C.9 6.1 2.5 3.6 5.2 3.2c1.6-.2 3.1.6 3.8 1.8.7-1.2 2.2-2 3.8-1.8 2.7.4 4.3 2.9 3.2 5.9-1.4 4-8 8.1-8 8.1Z"
                  stroke="currentColor"
                  strokeWidth="1.6"
                  strokeLinejoin="round"
                />
              </svg>
            </button>
            <button className="mc-action" type="button" aria-label="Panier">
              <svg width="18" height="18" viewBox="0 0 20 20" fill="none" aria-hidden="true">
                <path
                  d="M6.2 6.7V5.8a3.8 3.8 0 0 1 7.6 0v.9m-9.3 0h11l-1.1 10.5H5.6L4.5 6.7Z"
                  stroke="currentColor"
                  strokeWidth="1.6"
                  strokeLinecap="round"
                  strokeLinejoin="round"
                />
              </svg>
            </button>
          </div>
        </div>

        <nav className="mc-menu">
          <div className="mc-container mc-menu__inner">
            {MENU_LINKS.map((link) => (
              <NavLink
                key={link.to}
                to={link.to}
                className={({ isActive }) => `mc-menu__link${isActive ? ' is-active' : ''}`}
              >
                {link.label}
              </NavLink>
            ))}
          </div>
        </nav>
      </header>

      <AnimatePresence>
        {isSearchOpen ? (
          <MotionDiv
            className="mc-searchOverlay"
            role="dialog"
            aria-modal="true"
            aria-label="Rechercher"
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            transition={{ duration: 0.2 }}
          >
            <div className="mc-searchOverlay__backdrop" onClick={() => setIsSearchOpen(false)}></div>
            <MotionDiv
              className="mc-searchOverlay__panel"
              initial={{ opacity: 0, y: -20, scale: 0.96 }}
              animate={{ opacity: 1, y: 0, scale: 1 }}
              exit={{ opacity: 0, y: -10, scale: 0.98 }}
              transition={{ duration: 0.25, ease: [0.4, 0, 0.2, 1] }}
            >
              <form className="mc-search mc-search--overlay" role="search" onSubmit={submitSearch}>
                <input
                  className="mc-search__input"
                  key={urlQuery}
                  defaultValue={urlQuery}
                  ref={searchRef}
                  placeholder="Rechercher une montre, une marque…"
                  aria-label="Rechercher"
                />
                <button className="mc-search__btn" type="submit" aria-label="Lancer la recherche">
                  <svg width="18" height="18" viewBox="0 0 20 20" fill="none" aria-hidden="true">
                    <path
                      d="M13.58 13.58 18 18m-4.42-4.42A7 7 0 1 0 3.68 3.68a7 7 0 0 0 9.9 9.9Z"
                      stroke="currentColor"
                      strokeWidth="1.6"
                      strokeLinecap="round"
                    />
                  </svg>
                </button>
              </form>
            </MotionDiv>
          </MotionDiv>
        ) : null}
      </AnimatePresence>

      <a
        className="mc-whatsapp"
        href={`https://wa.me/212691567246?text=${encodeURIComponent(
          `Bonjour, je veux plus d\u2019informations sur une montre Maison Chrono.`,
        )}`}
        target="_blank"
        rel="noreferrer"
        aria-label="WhatsApp"
      >
        <svg width="24" height="24" viewBox="0 0 24 24" fill="none" aria-hidden="true">
          <path
            fill="currentColor"
            d="M20.52 3.48A11.91 11.91 0 0 0 12.01 0C5.39 0 .01 5.38.01 12c0 2.12.55 4.19 1.6 6.02L0 24l6.17-1.6A11.96 11.96 0 0 0 12 24h.01c6.62 0 12-5.38 12-12 0-3.2-1.25-6.21-3.49-8.52Zm-8.51 18.48h-.01c-1.82 0-3.6-.49-5.15-1.42l-.37-.22-3.66.95.98-3.57-.24-.37A9.95 9.95 0 0 1 2.02 12c0-5.5 4.48-9.98 9.99-9.98 2.67 0 5.18 1.04 7.07 2.93A9.93 9.93 0 0 1 22 12c0 5.51-4.48 9.99-9.99 9.99Zm5.48-7.5c-.3-.15-1.77-.87-2.04-.97-.28-.1-.48-.15-.68.15-.2.3-.78.97-.95 1.17-.18.2-.35.22-.65.07-.3-.15-1.25-.46-2.38-1.47-.88-.79-1.47-1.77-1.64-2.07-.17-.3-.02-.46.13-.6.14-.14.3-.35.45-.52.15-.17.2-.3.3-.5.1-.2.05-.37-.03-.52-.08-.15-.68-1.63-.93-2.23-.24-.58-.48-.5-.68-.5h-.58c-.2 0-.52.07-.8.37-.28.3-1.05 1.03-1.05 2.5s1.08 2.9 1.23 3.1c.15.2 2.13 3.25 5.16 4.56.72.31 1.28.5 1.72.64.72.23 1.38.2 1.9.12.58-.09 1.77-.72 2.02-1.42.25-.7.25-1.3.17-1.42-.08-.12-.27-.2-.57-.35Z"
          />
        </svg>
      </a>

      <main className="mc-main">
        <div className="mc-container">{children}</div>
      </main>

      <footer className="mc-footer">
        <div className="mc-trust" aria-label="Engagements">
          <div className="mc-container mc-trust__inner">
            <div className="mc-trust__item">
              <div className="mc-trust__icon" aria-hidden="true">
                <img className="mc-trust__img" src={deliveryIcon} alt="" />
              </div>
              <div className="mc-trust__title">Livraison</div>
              <div className="mc-trust__sub">Gratuite sur Casablanca · 35 DH hors Casablanca</div>
            </div>

            <div className="mc-trust__item">
              <div className="mc-trust__icon" aria-hidden="true">
                <img className="mc-trust__img mc-trust__img--pay" src={payIcon} alt="" />
              </div>
              <div className="mc-trust__title">Paiement</div>
              <div className="mc-trust__sub">À la livraison</div>
            </div>

            <div className="mc-trust__item">
              <div className="mc-trust__icon" aria-hidden="true">
                <img className="mc-trust__img" src={returnsIcon} alt="" />
              </div>
              <div className="mc-trust__title">Retours</div>
              <div className="mc-trust__sub">Sous 30 jours</div>
            </div>

            <div className="mc-trust__item">
              <div className="mc-trust__icon" aria-hidden="true">
                <img className="mc-trust__img" src={giftIcon} alt="" />
              </div>
              <div className="mc-trust__title">Emballage</div>
              <div className="mc-trust__sub">Cadeau soigné</div>
            </div>
          </div>
        </div>

        <div className="mc-footer__main">
          <div className="mc-container mc-footer__grid">
            <div className="mc-footer__brand">
              <NavLink className="mc-footer__logo" to="/">
                Maison Chrono
              </NavLink>
              <NavLink className="mc-footer__tag" to="/">
                Montres d'exception
              </NavLink>
              <a className="mc-footer__newsTitle" href="/contact">
                Newsletter
              </a>
              <a className="mc-footer__newsText" href="/contact">
                Inscrivez-vous pour recevoir les nouveautés et offres exclusives.
              </a>
              <form className="mc-footer__news" onSubmit={submitNewsletter}>
                <input
                  className="mc-input"
                  placeholder="Votre adresse email"
                  type="email"
                  ref={newsletterRef}
                  required
                />
                <button className="mc-btn mc-btn--primary" type="submit">
                  OK
                </button>
              </form>
              <div className="mc-footer__social" aria-label="Réseaux sociaux">
                <a className="mc-social" href="#" aria-label="Facebook">
                  <svg width="16" height="16" viewBox="0 0 24 24" fill="currentColor" aria-hidden="true"><path d="M24 12.073c0-6.627-5.373-12-12-12s-12 5.373-12 12c0 5.99 4.388 10.954 10.125 11.854v-8.385H7.078v-3.47h3.047V9.43c0-3.007 1.792-4.669 4.533-4.669 1.312 0 2.686.235 2.686.235v2.953H15.83c-1.491 0-1.956.925-1.956 1.874v2.25h3.328l-.532 3.47h-2.796v8.385C19.612 23.027 24 18.062 24 12.073z"/></svg>
                </a>
                <a className="mc-social" href="#" aria-label="Instagram">
                  <svg width="16" height="16" viewBox="0 0 24 24" fill="currentColor" aria-hidden="true"><path d="M12 2.163c3.204 0 3.584.012 4.85.07 3.252.148 4.771 1.691 4.919 4.919.058 1.265.069 1.645.069 4.849 0 3.205-.012 3.584-.069 4.849-.149 3.225-1.664 4.771-4.919 4.919-1.266.058-1.644.07-4.85.07-3.204 0-3.584-.012-4.849-.07-3.26-.149-4.771-1.699-4.919-4.92-.058-1.265-.07-1.644-.07-4.849 0-3.204.013-3.583.07-4.849.149-3.227 1.664-4.771 4.919-4.919 1.266-.057 1.645-.069 4.849-.069zM12 0C8.741 0 8.333.014 7.053.072 2.695.272.273 2.69.073 7.052.014 8.333 0 8.741 0 12c0 3.259.014 3.668.072 4.948.2 4.358 2.618 6.78 6.98 6.98C8.333 23.986 8.741 24 12 24c3.259 0 3.668-.014 4.948-.072 4.354-.2 6.782-2.618 6.979-6.98.059-1.28.073-1.689.073-4.948 0-3.259-.014-3.667-.072-4.947-.196-4.354-2.617-6.78-6.979-6.98C15.668.014 15.259 0 12 0zm0 5.838a6.162 6.162 0 100 12.324 6.162 6.162 0 000-12.324zM12 16a4 4 0 110-8 4 4 0 010 8zm6.406-11.845a1.44 1.44 0 100 2.881 1.44 1.44 0 000-2.881z"/></svg>
                </a>
                <a className="mc-social" href="#" aria-label="TikTok">
                  <svg width="16" height="16" viewBox="0 0 24 24" fill="currentColor" aria-hidden="true"><path d="M12.525.02c1.31-.02 2.61-.01 3.91-.02.08 1.53.63 3.09 1.75 4.17 1.12 1.11 2.7 1.62 4.24 1.79v4.03c-1.44-.05-2.89-.35-4.2-.97-.57-.26-1.1-.59-1.62-.93-.01 2.92.01 5.84-.02 8.75-.08 1.4-.54 2.79-1.35 3.94-1.31 1.92-3.58 3.17-5.91 3.21-1.43.08-2.86-.31-4.08-1.03-2.02-1.19-3.44-3.37-3.65-5.71-.02-.5-.03-1-.01-1.49.18-1.9 1.12-3.72 2.58-4.96 1.66-1.44 3.98-2.13 6.15-1.72.02 1.48-.04 2.96-.04 4.44-.99-.32-2.15-.23-3.02.37-.63.41-1.11 1.04-1.36 1.75-.21.51-.15 1.07-.14 1.61.24 1.64 1.82 3.02 3.5 2.87 1.12-.01 2.19-.66 2.77-1.61.19-.33.4-.67.41-1.06.1-1.79.06-3.57.07-5.36.01-4.03-.01-8.05.02-12.07z"/></svg>
                </a>
              </div>
            </div>

            <div className="mc-footer__col">
              <a className="mc-footer__colTitle" href="/a-propos">
                Maison
              </a>
              <a className="mc-footer__link" href="/a-propos">
                À propos
              </a>
              <a className="mc-footer__link" href="/contact">
                Contact
              </a>
              <a className="mc-footer__link" href="/catalogue">
                Catalogue
              </a>
            </div>

            <div className="mc-footer__col">
              <a className="mc-footer__colTitle" href="/contact">
                Services
              </a>
              <a className="mc-footer__link" href="/contact">
                Demande de renseignement
              </a>
              <a className="mc-footer__link" href="/contact">
                Livraison
              </a>
              <a className="mc-footer__link" href="/contact">
                Retours
              </a>
              <a className="mc-footer__link" href="/contact">
                Paiement
              </a>
            </div>

            <div className="mc-footer__col">
              <a className="mc-footer__colTitle" href="/catalogue">
                Sélections
              </a>
              <a className="mc-footer__link" href="/catalogue?tab=all">
                Nouveautés
              </a>
              <a className="mc-footer__link" href="/catalogue?tab=promo">
                Promotions
              </a>
              <a className="mc-footer__link" href="/catalogue?tab=best">
                Top ventes
              </a>
            </div>
          </div>

          <div className="mc-container mc-footer__bottom">
            <div className="mc-footer__line">
              <span>© {new Date().getFullYear()} Maison Chrono</span>
              <span className="mc-footer__sep" aria-hidden="true">
                ·
              </span>
              <span>Tous droits réservés</span>
            </div>
          </div>
        </div>
      </footer>
    </div>
  )
}
