// StandBy — dark, across-the-room

function StandByFrame({ children }) {
  return (
    <div style={{
      width: 580, height: 332, padding: 7,
      background: "#000", borderRadius: 32,
      border: "3px solid #1a1a1a",
      boxShadow: "inset 0 0 0 1.5px #222, 0 20px 60px rgba(0,0,0,0.5)",
    }}>
      <div style={{ width: "100%", height: "100%", borderRadius: 24, overflow: "hidden", background: "#000" }}>{children}</div>
    </div>
  );
}

function SBFrameWithStand({ children }) {
  return (
    <div style={{ display: "flex", flexDirection: "column", alignItems: "center" }}>
      <StandByFrame>{children}</StandByFrame>
      <div style={{ width: 150, height: 40, background: "#1a1a1a", borderRadius: "0 0 12px 12px", marginTop: -3, display: "flex", alignItems: "center", justifyContent: "center" }}>
        <div style={{ width: 80, height: 10, background: "#2a2a2a", borderRadius: 5 }}/>
      </div>
      <div style={{ width: 240, height: 16, background: "#2a2a2a", borderRadius: 8, marginTop: -6, filter: "blur(3px)", opacity: 0.5 }}/>
    </div>
  );
}

function SBA({ pace }) {
  const c = paceColor(pace);
  return (
    <div style={{ width: "100%", height: "100%", background: "#000", display: "flex", alignItems: "center", justifyContent: "center", position: "relative" }}>
      <div className="t-num" style={{ fontSize: 290, color: c, lineHeight: 0.85 }}>4</div>
      <div style={{ position: "absolute", bottom: 24, left: 0, right: 0, display: "flex", justifyContent: "space-between", padding: "0 32px", color: "var(--text-dim)", fontSize: 15, fontWeight: 500 }}>
        <span>of 8 clips</span>
        <span>next · 3:15 PM</span>
      </div>
    </div>
  );
}

function SBB({ pace }) {
  const c = paceColor(pace);
  return (
    <div style={{ width: "100%", height: "100%", background: "#000", display: "flex", alignItems: "center", justifyContent: "center", position: "relative" }}>
      <ProgressRing done={4} total={8} size={240} stroke={14} color={c}/>
      <div style={{ position: "absolute", textAlign: "center" }}>
        <div className="t-num" style={{ fontSize: 140, color: c, lineHeight: 0.9 }}>4</div>
        <div style={{ color: "var(--text-dim)", fontSize: 17, marginTop: -2, fontWeight: 600 }}>of 8</div>
      </div>
      <div style={{ position: "absolute", bottom: 20, right: 32, color: "var(--text-dim)", fontSize: 15, fontWeight: 500 }}>next 3:15 PM</div>
    </div>
  );
}

function SBC({ pace }) {
  const c = paceColor(pace);
  return (
    <div style={{ width: "100%", height: "100%", background: "#000", display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center", padding: 30, gap: 28 }}>
      <div style={{ display: "grid", gridTemplateColumns: "repeat(8, 1fr)", gap: 16, width: "88%" }}>
        {Array.from({length: 8}).map((_, i) => (
          <div key={i} style={{ aspectRatio: "1", borderRadius: "50%", background: i < 4 ? c : "transparent", border: `2px solid ${i < 4 ? c : "rgba(255,255,255,0.18)"}` }}/>
        ))}
      </div>
      <div style={{ display: "flex", gap: 26, color: "var(--text-dim)", fontSize: 17, fontWeight: 500 }}>
        <span style={{ color: c }}>4 of 8</span>
        <span style={{ color: "var(--text-mute)" }}>·</span>
        <span>next 3:15 PM</span>
      </div>
    </div>
  );
}

function SBD({ pace }) {
  const c = paceColor(pace);
  const pct = 0.5;
  return (
    <div style={{ width: "100%", height: "100%", background: "#000", position: "relative", display: "flex", alignItems: "center", justifyContent: "center" }}>
      <svg width="480" height="270" viewBox="0 0 480 270">
        <path d="M50 230 A 190 190 0 0 1 430 230" stroke="rgba(255,255,255,0.1)" strokeWidth="14" fill="none" strokeLinecap="round"/>
        <path d={`M50 230 A 190 190 0 0 1 ${50 + (430-50)*pct} ${230 - Math.sin(pct*Math.PI)*20}`} stroke={c} strokeWidth="14" fill="none" strokeLinecap="round"/>
        {Array.from({length: 9}).map((_,i) => {
          const a = Math.PI * (1 - i/8);
          const x1 = 240 + Math.cos(a)*205, y1 = 230 - Math.sin(a)*205;
          const x2 = 240 + Math.cos(a)*220, y2 = 230 - Math.sin(a)*220;
          return <line key={i} x1={x1} y1={y1} x2={x2} y2={y2} stroke="rgba(255,255,255,0.3)" strokeWidth="1.5"/>
        })}
      </svg>
      <div style={{ position: "absolute", top: 110, textAlign: "center" }}>
        <div className="t-num" style={{ color: c, fontSize: 140, lineHeight: 0.9 }}>4/8</div>
        <div style={{ color: "var(--text-dim)", fontSize: 15, marginTop: 6, fontWeight: 500 }}>next 3:15 PM</div>
      </div>
    </div>
  );
}

function StandByInner() {
  const [variant, setVariant] = React.useState("A");
  const [pace, setPace] = React.useState("yellow");
  const map = { A: <SBA pace={pace}/>, B: <SBB pace={pace}/>, C: <SBC pace={pace}/>, D: <SBD pace={pace}/> };

  return (
    <div style={{ padding: 32, display: "flex", gap: 36, background: "var(--bg)", minHeight: 860 }}>
      <div style={{ display: "flex", flexDirection: "column", alignItems: "center", gap: 12 }}>
        <div className="t-eyebrow">Nightstand · docked</div>
        <SBFrameWithStand>{map[variant]}</SBFrameWithStand>
        <div className="t-body" style={{ fontSize: 13, maxWidth: 430, textAlign: "center", marginTop: 14 }}>
          No Record button — you're across the room. Pace shifts green → yellow → orange. Never red.
        </div>
      </div>

      <div style={{ flex: 1, display: "flex", flexDirection: "column", gap: 20 }}>
        <div style={{ display: "flex", alignItems: "flex-end", justifyContent: "space-between" }}>
          <div>
            <div className="t-title" style={{ fontSize: 20 }}>StandBy</div>
            <div className="t-body" style={{ fontSize: 13, marginTop: 2 }}>Legibility at 6 feet. Giant numeral first; everything else secondary.</div>
          </div>
          <VariantToggle value={variant} onChange={setVariant} options={[{value:"A",label:"A"},{value:"B",label:"B"},{value:"C",label:"C"},{value:"D",label:"D"}]}/>
        </div>

        <div style={{ display: "flex", alignItems: "center", gap: 12 }}>
          <div className="t-caption">Pace state</div>
          <VariantToggle value={pace} onChange={setPace} options={[{value:"green",label:"On pace"},{value:"yellow",label:"Behind"},{value:"orange",label:"Well behind"}]}/>
        </div>

        <div style={{ display: "grid", gridTemplateColumns: "repeat(2, 1fr)", gap: 18 }}>
          {["A","B","C","D"].map(k => (
            <Pedestal key={k} selected={variant === k} onClick={() => setVariant(k)}>
              <div style={{ transform: "scale(0.55)", transformOrigin: "top left", width: 580, height: 332, marginRight: -262, marginBottom: -150 }}>
                <StandByFrame>{map[k] && ({ A: <SBA pace={pace}/>, B: <SBB pace={pace}/>, C: <SBC pace={pace}/>, D: <SBD pace={pace}/> }[k])}</StandByFrame>
              </div>
              <div style={{ display: "flex", gap: 8, alignItems: "center", alignSelf: "flex-start" }}>
                <span className="t-caption">Option {k}</span>
                <span className="t-body" style={{ fontSize: 13 }}>
                  {k==="A" && "Giant numeral"}
                  {k==="B" && "Number + ring"}
                  {k==="C" && "8 beads"}
                  {k==="D" && "Gauge dial"}
                </span>
              </div>
            </Pedestal>
          ))}
        </div>
      </div>
    </div>
  );
}

function StandByArtboard() {
  return <DCArtboard id="standby" label="StandBy" width={1480} height={860}><StandByInner/></DCArtboard>;
}
Object.assign(window, { StandByInner, StandByArtboard });
