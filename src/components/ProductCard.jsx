import { AnimatePresence, motion } from 'framer-motion'
import { useEffect, useState } from 'react'
import { Link } from 'react-router-dom'

import { useFavorites } from '../lib/favorites.js'

const numberFormatter = new Intl.NumberFormat('fr-FR', {
  maximumFractionDigits: 0,
})

function formatDh(value) {
  const n = typeof value === 'number' ? value : Number(value)
  const safe = Number.isFinite(n) ? n : 0
  return `${numberFormatter.format(safe)} DH`
}

export default function ProductCard({ product, index = 0, rotateImages = false }) {
  const MotionArticle = motion.article
  const { isFavorite, toggleFavorite } = useFavorites()
  const images = Array.isArray(product?.images) ? product.images : []
  const [activeImageIndex, setActiveImageIndex] = useState(0)
  const safeIndex = images.length > 0 ? activeImageIndex % images.length : 0
  const imageUrl = images[safeIndex] ?? null
  const brandName = product?.brands?.name ?? ''
  const categoryName = product?.categories?.name ?? ''
  const price = Number(product?.price ?? 0)
  const compareAt = product?.compare_at_price == null ? null : Number(product.compare_at_price)
  const hasDiscount = Number.isFinite(price) && Number.isFinite(compareAt) && compareAt > price
  const discountPercent = hasDiscount ? Math.round(((compareAt - price) / compareAt) * 100) : null
  const favorite = isFavorite(product?.id)

  useEffect(() => {
    if (images.length <= 1) return
    if (!rotateImages) return
    const id = window.setInterval(() => {
      setActiveImageIndex((i) => i + 1)
    }, 2200)
    return () => window.clearInterval(id)
  }, [images.length, product?.id, rotateImages])

  function onFavoriteClick(e) {
    e.preventDefault()
    e.stopPropagation()
    toggleFavorite(product)
  }

  return (
    <MotionArticle
      className="mc-card"
      initial={{ opacity: 0, y: 20 }}
      whileInView={{ opacity: 1, y: 0 }}
      viewport={{ once: true, margin: '-60px' }}
      transition={{ duration: 0.5, ease: [0.4, 0, 0.2, 1], delay: index * 0.08 }}
    >
      <Link to={`/produit/${product.id}`} className="mc-card__link">
        <div className="mc-card__media" aria-hidden="true">
          {discountPercent ? <div className="mc-discountBadge">-{discountPercent}%</div> : null}
          <button
            className={`mc-card__favBtn${favorite ? ' is-active' : ''}`}
            type="button"
            aria-label={favorite ? 'Retirer des favoris' : 'Ajouter aux favoris'}
            aria-pressed={favorite}
            onClick={onFavoriteClick}
          >
            <svg width="18" height="18" viewBox="0 0 20 20" fill="none" aria-hidden="true">
              <path
                d="M10 17.2s-6.6-4.1-8-8.1C.9 6.1 2.5 3.6 5.2 3.2c1.6-.2 3.1.6 3.8 1.8.7-1.2 2.2-2 3.8-1.8 2.7.4 4.3 2.9 3.2 5.9-1.4 4-8 8.1-8 8.1Z"
                stroke="currentColor"
                strokeWidth="1.6"
                strokeLinejoin="round"
                fill={favorite ? 'currentColor' : 'none'}
              />
            </svg>
          </button>
          {imageUrl ? (
            <AnimatePresence mode="wait">
              <motion.img
                key={imageUrl}
                src={imageUrl}
                alt=""
                loading="lazy"
                className="mc-card__img"
                style={{ position: 'absolute', inset: 0 }}
                initial={{ opacity: 0 }}
                animate={{ opacity: 1 }}
                exit={{ opacity: 0 }}
                transition={{ duration: 0.35 }}
              />
            </AnimatePresence>
          ) : (
            <div className="mc-card__img mc-card__img--placeholder"></div>
          )}
        </div>
        <div className="mc-card__body">
          <div className="mc-card__kicker">
            {brandName}
            {brandName && categoryName ? ' · ' : ''}
            {categoryName}
          </div>
          <h3 className="mc-card__title">{product.name}</h3>
          <div className="mc-card__meta">
            <span className="mc-card__price">
              {hasDiscount ? (
                <span className="mc-priceInline">
                  <span className="mc-priceNow">{formatDh(price)}</span>
                  <span className="mc-priceOld">{formatDh(compareAt)}</span>
                </span>
              ) : (
                formatDh(price)
              )}
            </span>
            <span className={`mc-badge${product.in_stock ? '' : ' is-muted'}`}>
              {product.in_stock ? 'Disponible' : 'Sur demande'}
            </span>
          </div>
        </div>
      </Link>
    </MotionArticle>
  )
}
