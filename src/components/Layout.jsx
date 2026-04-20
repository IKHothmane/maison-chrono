import { useEffect, useMemo, useRef, useState } from 'react'
import { NavLink, useLocation, useNavigate } from 'react-router-dom'

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

export default function Layout({ children }) {
  const navigate = useNavigate()
  const location = useLocation()
  const searchRef = useRef(null)
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

  return (
    <div className="mc-app">
      <header className="mc-header">
        <div className="mc-topbar">
          <div className="mc-container mc-topbar__inner">
            <div className="mc-topbar__msg">Livraison offerte aujourd’hui · Retours 30 jours</div>
          </div>
        </div>

        <div className="mc-container mc-header__main">
          <NavLink to="/" className="mc-brand" aria-label="Maison Chrono">
            <span className="mc-brand__mark" aria-hidden="true">
              <img src={logoImg} alt="" className="mc-brand__logo" />
            </span>
            <span className="mc-brand__text">
              <span className="mc-brand__name">Maison Chrono</span>
              <span className="mc-brand__tag">Montres d’exception</span>
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
      </header>

      {isSearchOpen ? (
        <div className="mc-searchOverlay" role="dialog" aria-modal="true" aria-label="Rechercher">
          <div className="mc-searchOverlay__backdrop" onClick={() => setIsSearchOpen(false)}></div>
          <div className="mc-searchOverlay__panel">
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
          </div>
        </div>
      ) : null}

      <a
        className="mc-whatsapp"
        href={`https://wa.me/212691567246?text=${encodeURIComponent(
          'Bonjour, je veux plus d’informations sur une montre Maison Chrono.',
        )}`}
        target="_blank"
        rel="noreferrer"
        aria-label="WhatsApp"
      >
        <svg width="22" height="22" viewBox="0 0 32 32" fill="none" aria-hidden="true">
          <path
            d="M16 3C9.383 3 4 8.22 4 14.64c0 2.52.87 4.86 2.35 6.76L5 29l7.83-1.29A12.48 12.48 0 0 0 16 26.28C22.617 26.28 28 21.06 28 14.64 28 8.22 22.617 3 16 3Z"
            fill="currentColor"
          />
          <path
            d="M22.98 19.3c-.28.77-1.38 1.4-2.05 1.52-.46.07-1.06.12-3.42-.7-3.03-1.07-4.98-3.7-5.13-3.9-.14-.2-1.23-1.6-1.23-3.05 0-1.45.77-2.17 1.06-2.46.24-.24.64-.35 1.03-.35h.74c.23 0 .55-.08.86.66.33.8 1.12 2.74 1.22 2.94.1.2.15.43.03.7-.11.26-.17.43-.34.66-.17.22-.35.5-.5.67-.17.2-.35.41-.15.8.2.38.9 1.48 1.93 2.4 1.32 1.18 2.43 1.54 2.8 1.72.38.18.6.15.83-.09.22-.24.95-1.08 1.2-1.45.24-.38.5-.31.84-.2.35.11 2.2 1.02 2.57 1.2.38.18.63.27.72.41.09.14.09.8-.2 1.57Z"
            fill="#0a0a0a"
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
              <div className="mc-footer__logo">Maison Chrono</div>
              <div className="mc-footer__tag">Montres d’exception</div>
              <div className="mc-footer__newsTitle">Newsletter</div>
              <div className="mc-footer__newsText">
                Inscrivez-vous pour recevoir les nouveautés et offres exclusives.
              </div>
              <form className="mc-footer__news" onSubmit={(e) => e.preventDefault()}>
                <input className="mc-input" placeholder="Votre adresse email" type="email" required />
                <button className="mc-btn mc-btn--primary" type="submit">
                  OK
                </button>
              </form>
              <div className="mc-footer__social" aria-label="Réseaux sociaux">
                <a className="mc-social" href="#" aria-label="Facebook">
                  f
                </a>
                <a className="mc-social" href="#" aria-label="Instagram">
                  in
                </a>
                <a className="mc-social" href="#" aria-label="TikTok">
                  t
                </a>
              </div>
            </div>

            <div className="mc-footer__col">
              <div className="mc-footer__colTitle">Maison</div>
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
              <div className="mc-footer__colTitle">Services</div>
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
              <div className="mc-footer__colTitle">Sélections</div>
              <a className="mc-footer__link" href="/catalogue">
                Nouveautés
              </a>
              <a className="mc-footer__link" href="/catalogue">
                Promotions
              </a>
              <a className="mc-footer__link" href="/catalogue">
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
