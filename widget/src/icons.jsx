// SF Symbols-style minimal icons (1.5px stroke, rounded caps)

function Icon({ d, size = 16, color = "currentColor", fill = "none", stroke = 1.6, style, children }) {
  return (
    <svg width={size} height={size} viewBox="0 0 24 24" fill={fill} stroke={color} strokeWidth={stroke} strokeLinecap="round" strokeLinejoin="round" style={style}>
      {d ? <path d={d}/> : children}
    </svg>
  );
}

// video.fill
function IconVideo({ size = 16, color = "currentColor", filled = false }) {
  return (
    <svg width={size} height={size} viewBox="0 0 24 24" fill={filled ? color : "none"} stroke={color} strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round">
      <rect x="2.5" y="7" width="13" height="10" rx="2.2"/>
      <path d="M15.5 11 L21 8.5 V15.5 L15.5 13 Z"/>
    </svg>
  );
}

// record.circle
function IconRecord({ size = 16, color = "currentColor" }) {
  return (
    <svg width={size} height={size} viewBox="0 0 24 24" fill="none" stroke={color} strokeWidth="1.5">
      <circle cx="12" cy="12" r="9.25"/>
      <circle cx="12" cy="12" r="4.5" fill={color} stroke="none"/>
    </svg>
  );
}

// clock
function IconClock({ size = 14, color = "currentColor" }) {
  return (
    <svg width={size} height={size} viewBox="0 0 24 24" fill="none" stroke={color} strokeWidth="1.6" strokeLinecap="round" strokeLinejoin="round">
      <circle cx="12" cy="12" r="9.25"/>
      <path d="M12 7v5l3.2 2.2"/>
    </svg>
  );
}

// lightbulb
function IconBulb({ size = 14, color = "currentColor" }) {
  return (
    <svg width={size} height={size} viewBox="0 0 24 24" fill="none" stroke={color} strokeWidth="1.6" strokeLinecap="round" strokeLinejoin="round">
      <path d="M9.5 18h5M10.5 21h3M12 3a5.5 5.5 0 0 0-3.5 9.75c.85.85 1.3 1.75 1.3 3.25h4.4c0-1.5.45-2.4 1.3-3.25A5.5 5.5 0 0 0 12 3z"/>
    </svg>
  );
}

// chevron.right (tiny)
function IconChevron({ size = 12, color = "currentColor" }) {
  return <svg width={size} height={size} viewBox="0 0 24 24" fill="none" stroke={color} strokeWidth="2" strokeLinecap="round"><path d="M9 6l6 6-6 6"/></svg>;
}

// simple app-mark placeholder for the widget header
function AppMark({ size = 14 }) {
  return (
    <div style={{ width: size, height: size, borderRadius: size * 0.28, background: "var(--record)", display: "grid", placeItems: "center", boxShadow: "0 0 0 0.5px rgba(0,0,0,0.3)" }}>
      <div style={{ width: size * 0.46, height: size * 0.46, borderRadius: "50%", background: "#fff" }}/>
    </div>
  );
}

Object.assign(window, { Icon, IconVideo, IconRecord, IconClock, IconBulb, IconChevron, AppMark });
