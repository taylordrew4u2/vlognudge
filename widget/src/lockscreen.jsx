// Lock Screen — dark aesthetic

const lockCardGlass = {
  background: "rgba(255,255,255,0.12)",
  backdropFilter: "blur(20px) saturate(140%)",
  border: "1px solid rgba(255,255,255,0.08)",
  borderRadius: 16,
  color: "#fff",
  fontFamily: "var(--font-rounded)",
};

function LockFrame({ children, inline }) {
  return (
    <div className="phone">
      <div className="phone-screen" style={{
        background: "linear-gradient(180deg, #0f1320 0%, #151019 55%, #1a0f15 100%)",
        display: "flex", flexDirection: "column", alignItems: "center", padding: "46px 16px 20px",
      }}>
        <div style={{ width: 96, height: 28, background: "#000", borderRadius: 14, marginBottom: 14 }}/>
        {inline}
        <div style={{ color: "rgba(255,255,255,0.72)", fontSize: 13, fontWeight: 500, marginTop: inline ? 6 : 10 }}>
          Tuesday, April 21
        </div>
        <div style={{ color: "#fff", fontSize: 82, fontSmoothing: "antialiased", fontWeight: 200, lineHeight: 1, letterSpacing: "-0.04em", marginTop: -4, fontFamily: "var(--font-rounded)" }}>3:02</div>
        <div style={{ marginTop: 20, width: "100%", display: "flex", flexDirection: "column", alignItems: "center", gap: 10 }}>
          {children}
        </div>
      </div>
    </div>
  );
}

const RECT = { w: 172, h: 80 };

function LockRectA({ pace }) {
  return (
    <div style={{ ...lockCardGlass, width: RECT.w, height: RECT.h, padding: "10px 12px", display: "flex", flexDirection: "column", justifyContent: "space-between" }}>
      <div style={{ display: "flex", alignItems: "center", gap: 6 }}>
        <IconVideo size={12} color="#fff"/>
        <span className="t-num" style={{ fontSize: 22, color: "#fff" }}>4/8</span>
        <span style={{ marginLeft: "auto", fontSize: 10, color: "rgba(255,255,255,0.6)", fontWeight: 500 }}>clips</span>
      </div>
      <Dots done={4} total={8} size={7} color="#fff" trackColor="rgba(255,255,255,0.25)"/>
      <div style={{ fontSize: 10, color: "rgba(255,255,255,0.7)", fontWeight: 500 }}>Next · 3:15 PM</div>
    </div>
  );
}

function LockRectB({ pace }) {
  return (
    <div style={{ ...lockCardGlass, width: RECT.w, height: RECT.h, padding: "10px 12px", display: "flex", flexDirection: "column", gap: 6, justifyContent: "center" }}>
      <div style={{ display: "flex", alignItems: "baseline", gap: 6 }}>
        <span style={{ fontWeight: 600, fontSize: 13, color: "rgba(255,255,255,0.7)" }}>VlogNudge</span>
        <span className="t-num" style={{ fontSize: 18, color: "#fff", marginLeft: "auto" }}>4/8</span>
      </div>
      <CellStrip done={4} total={8} w={148} h={5} color="#fff" trackColor="rgba(255,255,255,0.2)"/>
      <div style={{ fontSize: 10, color: "rgba(255,255,255,0.7)", fontWeight: 500 }}>next 3:15 PM · 13m</div>
    </div>
  );
}

function LockRectC({ pace }) {
  return (
    <div style={{ ...lockCardGlass, width: RECT.w, height: RECT.h, padding: "8px 12px", display: "flex", alignItems: "center", gap: 12 }}>
      <SegmentedRing done={4} total={8} size={60} stroke={6} color="#fff" trackColor="rgba(255,255,255,0.2)"/>
      <div style={{ display: "flex", flexDirection: "column", gap: 1 }}>
        <span className="t-num" style={{ fontSize: 22, color: "#fff" }}>4/8</span>
        <span style={{ fontSize: 10, color: "rgba(255,255,255,0.7)", fontWeight: 500 }}>next 3:15 PM</span>
        <span style={{ fontSize: 9, color: "rgba(255,255,255,0.5)" }}>last · 2h ago</span>
      </div>
    </div>
  );
}

function LockRectD({ pace }) {
  const nowPct = 0.42;
  return (
    <div style={{ ...lockCardGlass, width: RECT.w, height: RECT.h, padding: "10px 12px", display: "flex", flexDirection: "column", justifyContent: "space-between" }}>
      <div style={{ display: "flex", justifyContent: "space-between", alignItems: "baseline" }}>
        <span className="t-num" style={{ fontSize: 22, color: "#fff" }}>4/8</span>
        <span style={{ fontSize: 9, color: "rgba(255,255,255,0.6)", fontWeight: 500, letterSpacing: "0.04em" }}>10A → 10P</span>
      </div>
      <div style={{ position: "relative", height: 16 }}>
        <div style={{ position: "absolute", left: 0, right: 0, top: 7, height: 1, background: "rgba(255,255,255,0.2)" }}/>
        {[0,1,2,3,4,5,6,7].map(i => {
          const p = i / 7;
          return <div key={i} style={{ position: "absolute", top: 3, left: `${p*100}%`, transform: "translateX(-50%)", width: 8, height: 8, borderRadius: "50%", background: i < 4 ? "#fff" : "transparent", border: "1px solid rgba(255,255,255,0.7)" }}/>;
        })}
        <div style={{ position: "absolute", top: -2, left: `${nowPct*100}%`, transform: "translateX(-50%)", width: 1, height: 20, background: "var(--record)" }}/>
      </div>
      <div style={{ fontSize: 10, color: "rgba(255,255,255,0.75)", fontWeight: 500 }}>next · 3:15 PM</div>
    </div>
  );
}

const CIRC = 72;
const circStyle = { ...lockCardGlass, width: CIRC, height: CIRC, borderRadius: "50%", display: "grid", placeItems: "center" };

function LockCircA({ pace }) { return <div style={circStyle}><ProgressRing done={4} total={8} size={56} stroke={5} color="#fff" trackColor="rgba(255,255,255,0.18)"/><div style={{ position: "absolute", fontSize: 14, fontWeight: 700, color: "#fff" }}>4/8</div></div>; }
function LockCircB({ pace }) { return <div style={{...circStyle, position: "relative"}}><SegmentedRing done={4} total={8} size={58} stroke={6} color="#fff" trackColor="rgba(255,255,255,0.2)"/><div style={{ position: "absolute", fontSize: 18, fontWeight: 700, color: "#fff" }}>4</div></div>; }
function LockCircC({ pace }) {
  return (
    <div style={circStyle}>
      <div style={{ textAlign: "center", lineHeight: 0.95 }}>
        <div className="t-num" style={{ fontSize: 26, color: "#fff" }}>4</div>
        <div style={{ width: 18, height: 1, background: "rgba(255,255,255,0.5)", margin: "2px auto" }}/>
        <div style={{ fontWeight: 600, fontSize: 15, color: "rgba(255,255,255,0.6)" }}>8</div>
      </div>
    </div>
  );
}
function LockCircD({ pace }) {
  const r = 26;
  return (
    <div style={{ ...circStyle, position: "relative" }}>
      <svg width={CIRC} height={CIRC} style={{ position: "absolute", inset: 0 }}>
        {Array.from({length: 8}).map((_, i) => {
          const a = (i / 8) * Math.PI * 2 - Math.PI/2;
          const cx = CIRC/2 + Math.cos(a) * r;
          const cy = CIRC/2 + Math.sin(a) * r;
          return <circle key={i} cx={cx} cy={cy} r="3.5" fill={i < 4 ? "#fff" : "none"} stroke="rgba(255,255,255,0.8)" strokeWidth="1"/>;
        })}
      </svg>
      <div style={{ position: "relative", fontSize: 16, fontWeight: 700, color: "#fff" }}>4</div>
    </div>
  );
}

function LockInlineA() { return <div style={{ display: "flex", alignItems: "center", gap: 5, color: "rgba(255,255,255,0.9)", fontSize: 12, fontWeight: 500 }}><IconVideo size={11} color="rgba(255,255,255,0.9)"/>Vlog 4/8 · next 3:15 PM</div>; }
function LockInlineB() { return <div style={{ display: "flex", alignItems: "center", gap: 5, color: "rgba(255,255,255,0.9)", fontSize: 12, fontWeight: 500 }}><Dots done={4} total={8} size={5} color="#fff" trackColor="rgba(255,255,255,0.3)"/><span style={{marginLeft:4}}>next 3:15 PM</span></div>; }
function LockInlineC({ pace }) { return <div style={{ display: "flex", alignItems: "center", gap: 5, color: "rgba(255,255,255,0.9)", fontSize: 12, fontWeight: 500 }}><span style={{ width: 6, height: 6, borderRadius: "50%", background: paceColor(pace) }}/>4 of 8 · 13m until nudge</div>; }

function LockScreenInner() {
  const [rect, setRect] = React.useState("A");
  const [circ, setCirc] = React.useState("A");
  const [inline, setInline] = React.useState("A");
  const pace = "yellow";

  const rectMap = { A: <LockRectA pace={pace}/>, B: <LockRectB pace={pace}/>, C: <LockRectC pace={pace}/>, D: <LockRectD pace={pace}/> };
  const circMap = { A: <LockCircA pace={pace}/>, B: <LockCircB pace={pace}/>, C: <LockCircC pace={pace}/>, D: <LockCircD pace={pace}/> };
  const inlineMap = { A: <LockInlineA/>, B: <LockInlineB/>, C: <LockInlineC pace={pace}/> };
  const opts3 = [{value:"A",label:"A"},{value:"B",label:"B"},{value:"C",label:"C"}];
  const opts4 = [...opts3, {value:"D",label:"D"}];

  return (
    <div style={{ padding: 32, display: "flex", gap: 36, minHeight: 1050, background: "var(--bg)" }}>
      <div style={{ display: "flex", flexDirection: "column", alignItems: "center", gap: 12, flexShrink: 0 }}>
        <div className="t-eyebrow">In context</div>
        <LockFrame inline={inlineMap[inline]}>
          {rectMap[rect]}
          <div style={{ display: "flex", gap: 10 }}>
            {circMap[circ]}
            <div style={{ width: CIRC, height: CIRC, borderRadius: "50%", border: "1px dashed rgba(255,255,255,0.2)", display: "grid", placeItems: "center", fontSize: 10, color: "rgba(255,255,255,0.4)", fontFamily: "var(--font-rounded)" }}>empty</div>
          </div>
        </LockFrame>
      </div>

      <div style={{ flex: 1, display: "flex", flexDirection: "column", gap: 32 }}>
        {[
          { title: "Rectangular", caption: "The useful one — count, next nudge, progress. Tap to jump to Record.", value: rect, setValue: setRect, map: rectMap, opts: opts4, keys: ["A","B","C","D"] },
          { title: "Circular", caption: "One-glyph summary for the small slot.", value: circ, setValue: setCirc, map: circMap, opts: opts4, keys: ["A","B","C","D"] },
          { title: "Inline", caption: "A single line above the clock — the quietest nudge.", value: inline, setValue: setInline, map: inlineMap, opts: opts3, keys: ["A","B","C"] },
        ].map(row => (
          <div key={row.title}>
            <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between", marginBottom: 14 }}>
              <div>
                <div className="t-title" style={{ fontSize: 18 }}>{row.title}</div>
                <div className="t-body" style={{ fontSize: 13, marginTop: 2 }}>{row.caption}</div>
              </div>
              <VariantToggle value={row.value} onChange={row.setValue} options={row.opts}/>
            </div>
            <div style={{ display: "grid", gridTemplateColumns: `repeat(${row.keys.length}, 1fr)`, gap: 14 }}>
              {row.keys.map(k => (
                <Pedestal key={k} selected={row.value === k} onClick={() => row.setValue(k)}>
                  <div style={{ padding: row.title === "Inline" ? "10px 16px" : 16, borderRadius: row.title === "Circular" ? "50%" : 18, background: "linear-gradient(180deg, #0f1320, #1a0f15)", display: "grid", placeItems: "center" }}>
                    {row.map[k]}
                  </div>
                  <div className="t-caption">Option {k}</div>
                </Pedestal>
              ))}
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}

function LockScreenArtboard() {
  return <DCArtboard id="lock-screen" label="Lock Screen" width={1480} height={1080}><LockScreenInner/></DCArtboard>;
}
Object.assign(window, { LockScreenInner, LockScreenArtboard });
