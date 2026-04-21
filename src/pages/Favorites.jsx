import ProductCard from '../components/ProductCard.jsx'
import { useFavorites } from '../lib/favorites.js'

export default function Favorites() {
  const { favorites } = useFavorites()

  return (
    <div className="mc-stack">
      <section className="mc-section">
        <div className="mc-section__head">
          <h1 className="mc-section__title">Favoris</h1>
        </div>
        {favorites.length === 0 ? (
          <div className="mc-muted">Aucun produit en favoris.</div>
        ) : (
          <div className="mc-grid mc-grid--catalog">
            {favorites.map((p) => (
              <ProductCard key={p.id} product={p} />
            ))}
          </div>
        )}
      </section>
    </div>
  )
}
