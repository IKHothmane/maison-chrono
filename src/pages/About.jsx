import { motion } from 'framer-motion'

export default function About() {
  const MotionDiv = motion.div
  return (
    <MotionDiv
      className="mc-stack"
      initial={{ opacity: 0, y: 14 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ duration: 0.6, ease: 'easeOut' }}
    >
      <header className="mc-pagehead">
        <h1 className="mc-pagehead__title">À propos</h1>
        <p className="mc-pagehead__subtitle">
          Une sélection exigeante, une présentation premium, une expérience sobre et rapide.
        </p>
      </header>

      <section className="mc-panel">
        <div className="mc-prose">
          <p>
            Maison Chrono est une vitrine e-commerce dédiée aux montres de luxe. L’objectif est
            simple : mettre en valeur chaque pièce avec des visuels soignés, des spécifications
            claires et un parcours de demande de renseignement sans friction.
          </p>
          <p>
            L’expérience est pensée pour être élégante, minimaliste et immersive, avec des
            animations discrètes et une palette inspirée des codes horlogers.
          </p>
        </div>
      </section>
    </MotionDiv>
  )
}
