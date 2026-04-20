export default function Notice({ title, children, tone = 'info' }) {
  return (
    <div className={`mc-notice mc-notice--${tone}`} role={tone === 'danger' ? 'alert' : undefined}>
      {title ? <div className="mc-notice__title">{title}</div> : null}
      <div className="mc-notice__body">{children}</div>
    </div>
  )
}

