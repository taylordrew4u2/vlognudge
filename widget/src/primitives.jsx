// Shared primitives — dark aesthetic, muted palette

const MOCK = {
  clipsDone: 4,
  target: 8,
  nextNudge: "3:15 PM",
  lastClip: "2h ago",
  lastClipTime: "1:12 PM",
  now: "3:02 PM",
  pace: "yellow",
  windowOpen: "10 AM",
  windowClose: "10 PM",
};

const paceColor = (p) => ({
  green:  "var(--pace-green)",
  yellow: "var(--pace-yellow)",
  orange: "var(--pace-orange)",
}[p] || "var(--text)");

// Progress ring
function ProgressRing({ done, total, size = 72, stroke = 5, color = "currentColor", trackColor = "rgba(255,255,255,0.08)" }) {
  const r = (size - stroke) / 2;
  const c = 2 * Math.PI * r;
  const pct = Math.min(1, done / total);
  return (
    <svg width={size} height={size} style={{ overflow: "visible", display: "block" }}>
      <circle cx={size/2} cy={size/2} r={r} stroke={trackColor} strokeWidth={stroke} fill="none"/>
      <circle cx={size/2} cy={size/2} r={r}
        stroke={color} strokeWidth={stroke} fill="none"
        strokeLinecap="round"
        strokeDasharray={`${c * pct} ${c}`}
        transform={`rotate(-90 ${size/2} ${size/2})`}/>
    </svg>
  );
}

// 8 segmented arcs (pie-slice ring)
function SegmentedRing({ done, total, size = 72, stroke = 6, color = "currentColor", trackColor = "rgba(255,255,255,0.1)" }) {
  const r = (size - stroke) / 2;
  const c = 2 * Math.PI * r;
  const seg = c / total;
  const gap = seg * 0.22;
  return (
    <svg width={size} height={size} style={{ overflow: "visible" }}>
      {Array.from({ length: total }).map((_, i) => {
        const filled = i < done;
        const offset = -c * (i / total);
        return (
          <circle key={i} cx={size/2} cy={size/2} r={r}
            stroke={filled ? color : trackColor}
            strokeWidth={stroke} fill="none"
            strokeLinecap="round"
            strokeDasharray={`${seg - gap} ${c - (seg - gap)}`}
            strokeDashoffset={offset}
            transform={`rotate(-90 ${size/2} ${size/2})`}/>
        );
      })}
    </svg>
  );
}

// Horizontal 8-cell progress strip
function CellStrip({ done, total, w = 140, h = 6, color = "currentColor", trackColor = "rgba(255,255,255,0.12)", gap = 3 }) {
  const cellW = (w - gap * (total - 1)) / total;
  return (
    <div style={{ display: "flex", gap, width: w }}>
      {Array.from({ length: total }).map((_, i) => (
        <div key={i} style={{
          width: cellW, height: h, borderRadius: h/2,
          background: i < done ? color : trackColor,
        }}/>
      ))}
    </div>
  );
}

// Dots row (small)
function Dots({ done, total, size = 6, gap = 4, color = "currentColor", trackColor = "rgba(255,255,255,0.18)" }) {
  return (
    <div style={{ display: "inline-flex", gap, alignItems: "center" }}>
      {Array.from({ length: total }).map((_, i) => (
        <span key={i} className="dot" style={{ width: size, height: size, background: i < done ? color : trackColor }}/>
      ))}
    </div>
  );
}

// Variant toggle (segmented pill)
function VariantToggle({ value, onChange, options }) {
  return (
    <div className="pill">
      {options.map(o => (
        <button key={o.value} className={value === o.value ? "active" : ""} onClick={() => onChange(o.value)}>
          {o.label}
        </button>
      ))}
    </div>
  );
}

// Artboard chrome — dark, quiet
function Board({ label, children, style }) {
  return (
    <div style={{ display: "flex", flexDirection: "column", gap: 10, ...style }}>
      {label && <div className="t-eyebrow">{label}</div>}
      {children}
    </div>
  );
}

// Widget preview pedestal — a soft surface under a captured widget shot
function Pedestal({ children, wrap, selected = false, onClick, style }) {
  return (
    <div onClick={onClick} style={{
      padding: 20,
      borderRadius: 18,
      background: selected ? "rgba(229,57,53,0.06)" : "var(--bg-elev)",
      border: `1px solid ${selected ? "rgba(229,57,53,0.35)" : "var(--hairline)"}`,
      display: "flex", flexDirection: "column", alignItems: "center", gap: 12,
      cursor: onClick ? "pointer" : "default",
      transition: "border-color .12s, background .12s",
      ...style,
    }}>
      {children}
    </div>
  );
}

Object.assign(window, {
  MOCK, paceColor,
  ProgressRing, SegmentedRing, CellStrip, Dots,
  VariantToggle, Board, Pedestal,
});
