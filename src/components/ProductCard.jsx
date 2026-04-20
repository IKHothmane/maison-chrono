import { motion } from 'framer-motion'
import { Link } from 'react-router-dom'

const numberFormatter = new Intl.NumberFormat('fr-FR', {
  maximumFractionDigits: 0,
})

function formatDh(value) {
  const n = typeof value === 'number' ? value : Number(value)
  const safe = Number.isFinite(n) ? n : 0
  return `${numberFormatter.format(safe)} DH`
}

export default function ProductCard({ product, index = 0 }) {
  const MotionArticle = motion.article
  const imageUrl = product?.images?.[0] ?? null
  const brandName = product?.brands?.name ?? ''
  const categoryName = product?.categories?.name ?? ''
  const price = Number(product?.price ?? 0)
  const compareAt = product?.compare_at_price == null ? null : Number(product.compare_at_price)
  const hasDiscount = Number.isFinite(price) && Number.isFinite(compareAt) && compareAt > price

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
          {imageUrl ? (
            <img src={imageUrl} alt="" loading="lazy" className="mc-card__img" />
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
