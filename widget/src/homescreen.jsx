// Home Screen widgets — dark, Kodak red, SF Rounded, muted pace colors

function HomeFrame({ children }) {
  return (
    <div className="phone">
      <div className="phone-screen" style={{
        background: "radial-gradient(140% 90% at 50% 0%, #2a2a30 0%, #0f0f12 60%)",
        display: "flex", flexDirection: "column", padding: "46px 14px 18px",
      }}>
        <div style={{ width: 96, height: 28, background: "#000", borderRadius: 14, margin: "0 auto 16px" }}/>
        <div style={{ color: "var(--text-dim)", fontSize: 11, textAlign: "center", marginBottom: 12, fontWeight: 500, letterSpacing: "0.02em" }}>
          Tue, Apr 21 · 3:02
        </div>
        <div style={{ display: "grid", gridTemplateColumns: "repeat(4, 1fr)", gap: 10, marginBottom: 14 }}>
          {Array.from({length: 4}).map((_, i) => (
            <div key={i} style={{ aspectRatio: "1", borderRadius: 13, background: "rgba(255,255,255,0.05)", border: "1px solid rgba(255,255,255,0.04)" }}/>
          ))}
        </div>
        {children}
        <div style={{ marginTop: "auto", display: "flex", justifyContent: "space-around", padding: 8, background: "rgba(255,255,255,0.04)", borderRadius: 22, backdropFilter: "blur(8px)" }}>
          {Array.from({length:4}).map((_,i)=>(<div key={i} style={{ width: 42, height: 42, borderRadius: 11, background: "rgba(255,255,255,0.08)" }}/>))}
        </div>
      </div>
    </div>
  );
}

const cardDark = {
  background: "rgba(28,28,30,0.92)",
  border: "1px solid rgba(255,255,255,0.06)",
  borderRadius: 22,
  color: "var(--text)",
  boxShadow: "0 8px 24px rgba(0,0,0,0.45)",
  backdropFilter: "blur(20px) saturate(140%)",
};

// Header row: app mark + name + right meta
function WHeader({ right, label = "VlogNudge" }) {
  return (
    <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between" }}>
      <div style={{ display: "flex", alignItems: "center", gap: 6 }}>
        <AppMark size={14}/>
        <span style={{ fontSize: 11, fontWeight: 600, color: "var(--text-dim)", letterSpacing: "-0.01em" }}>{label}</span>
      </div>
      {right}
    </div>
  );
}

// ---- Small (160×160 in widget units, we scale to 150) ----
function HomeSmallA({ pace = "yellow" }) {
  return (
    <div style={{ ...cardDark, width: 156, height: 156, padding: 14, display: "flex", flexDirection: "column", justifyContent: "space-between" }}>
      <WHeader/>
      <div>
        <div className="t-num" style={{ fontSize: 54, lineHeight: 0.9 }}>
          4<span style={{ fontWeight: 600, color: "var(--text-faint)", fontSize: 28 }}>/8</span>
        </div>
        <div style={{ fontSize: 11, color: "var(--text-dim)", fontWeight: 500, marginTop: 2 }}>clips today</div>
      </div>
      <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between" }}>
        <Dots done={4} total={8} size={6} color={paceColor(pace)}/>
        <button style={{ width: 30, height: 30, borderRadius: "50%", background: "var(--record)", border: "none", display: "grid", placeItems: "center", cursor: "pointer", boxShadow: "0 0 0 3px var(--record-soft)" }}>
          <div style={{ width: 12, height: 12, borderRadius: 3, background: "#fff" }}/>
        </button>
      </div>
    </div>
  );
}

function HomeSmallB({ pace = "yellow" }) {
  return (
    <div style={{ ...cardDark, width: 156, height: 156, padding: 14, display: "flex", flexDirection: "column", justifyContent: "space-between" }}>
      <WHeader right={<IconClock size={11} color="var(--text-faint)"/>}/>
      <div style={{ display: "flex", justifyContent: "center", position: "relative" }}>
        <SegmentedRing done={4} total={8} size={90} stroke={7} color={paceColor(pace)}/>
        <div style={{ position: "absolute", top: "50%", left: "50%", transform: "translate(-50%, -50%)", textAlign: "center" }}>
          <div className="t-num" style={{ fontSize: 28, lineHeight: 1 }}>4<span style={{ fontWeight: 600, color: "var(--text-faint)", fontSize: 16 }}>/8</span></div>
        </div>
      </div>
      <div style={{ fontSize: 11, color: "var(--text-dim)", textAlign: "center", fontWeight: 500 }}>next 3:15 PM</div>
    </div>
  );
}

function HomeSmallC({ pace = "yellow" }) {
  return (
    <div style={{ ...cardDark, width: 156, height: 156, padding: 14, display: "flex", flexDirection: "column", gap: 8 }}>
      <WHeader/>
      <div className="t-num" style={{ fontSize: 42, lineHeight: 0.95 }}>4<span style={{ fontWeight: 600, color: "var(--text-faint)", fontSize: 22 }}> / 8</span></div>
      <div style={{ marginTop: "auto" }}>
        <CellStrip done={4} total={8} w={128} h={4} color={paceColor(pace)}/>
        <div style={{ display: "flex", justifyContent: "space-between", marginTop: 8, fontSize: 10, color: "var(--text-faint)", fontWeight: 500 }}>
          <span>next · 3:15 PM</span>
          <span>in 13m</span>
        </div>
      </div>
    </div>
  );
}

// ---- Medium (2:1, 330×156) ----
function HomeMedA({ pace = "yellow" }) {
  return (
    <div style={{ ...cardDark, width: 336, height: 156, padding: "14px 16px", display: "flex", gap: 14 }}>
      <div style={{ flex: 1, display: "flex", flexDirection: "column", justifyContent: "space-between" }}>
        <WHeader/>
        <div>
          <div className="t-num" style={{ fontSize: 64, lineHeight: 0.9 }}>
            4<span style={{ fontWeight: 600, color: "var(--text-faint)", fontSize: 30 }}>/8</span>
          </div>
          <div style={{ fontSize: 12, color: "var(--text-dim)", fontWeight: 500, marginTop: 2 }}>next · <span style={{ color: "var(--text)" }}>3:15 PM</span> · in 13m</div>
        </div>
      </div>
      <div style={{ display: "flex", flexDirection: "column", alignItems: "stretch", justifyContent: "space-between", minWidth: 110, paddingTop: 2 }}>
        <div style={{ display: "flex", justifyContent: "flex-end" }}>
          <Dots done={4} total={8} size={7} color={paceColor(pace)}/>
        </div>
        <button style={{
          background: "var(--record)", color: "#fff", border: "none",
          borderRadius: 14, padding: "12px 14px", fontWeight: 600, fontSize: 13,
          display: "flex", alignItems: "center", justifyContent: "center", gap: 7, cursor: "pointer",
          fontFamily: "var(--font-rounded)", letterSpacing: "-0.01em",
          boxShadow: "0 0 0 0 rgba(229,57,53,0)",
        }}>
          <div style={{ width: 10, height: 10, borderRadius: "50%", background: "#fff" }}/> Record
        </button>
      </div>
    </div>
  );
}

function HomeMedB({ pace = "yellow" }) {
  return (
    <div style={{ ...cardDark, width: 336, height: 156, padding: "14px 16px", display: "flex", flexDirection: "column", gap: 10 }}>
      <WHeader right={<span style={{ fontSize: 10, color: "var(--text-faint)", fontWeight: 500, letterSpacing: "0.04em" }}>TUE · 3:02 PM</span>}/>
      <div className="t-num" style={{ fontSize: 38, lineHeight: 1 }}>
        4 <span style={{ color: "var(--text-faint)", fontWeight: 600, fontSize: 24 }}>of 8 clips</span>
      </div>
      <CellStrip done={4} total={8} w={304} h={6} color={paceColor(pace)}/>
      <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between", marginTop: "auto" }}>
        <div style={{ fontSize: 12, color: "var(--text-dim)" }}>next <span style={{ color: "var(--text)" }}>3:15 PM</span> · last 2h ago</div>
        <button style={{ background: "var(--record)", color: "#fff", border: "none", borderRadius: 11, padding: "7px 12px", fontWeight: 600, fontSize: 12, display: "flex", alignItems: "center", gap: 6, cursor: "pointer", fontFamily: "var(--font-rounded)" }}>
          <div style={{ width: 8, height: 8, borderRadius: "50%", background: "#fff" }}/> Record
        </button>
      </div>
    </div>
  );
}

function HomeMedC({ pace = "yellow" }) {
  return (
    <div style={{ ...cardDark, width: 336, height: 156, padding: 14, display: "flex", gap: 16, alignItems: "center" }}>
      <div style={{ position: "relative" }}>
        <SegmentedRing done={4} total={8} size={124} stroke={10} color={paceColor(pace)}/>
        <div style={{ position: "absolute", inset: 0, display: "grid", placeItems: "center" }}>
          <div className="t-num" style={{ fontSize: 36, lineHeight: 1 }}>4<span style={{ fontWeight: 600, fontSize: 18, color: "var(--text-faint)" }}>/8</span></div>
        </div>
      </div>
      <div style={{ flex: 1, display: "flex", flexDirection: "column", gap: 6 }}>
        <WHeader/>
        <div style={{ fontSize: 12, color: "var(--text-dim)", fontWeight: 500 }}>next · <span style={{ color: "var(--text)" }}>3:15 PM</span></div>
        <div style={{ fontSize: 11, color: "var(--text-faint)" }}>last · 2h ago</div>
        <button style={{ marginTop: 4, background: "var(--record)", color: "#fff", border: "none", borderRadius: 11, padding: "8px 10px", fontWeight: 600, fontSize: 12, display: "flex", alignItems: "center", justifyContent: "center", gap: 6, cursor: "pointer", fontFamily: "var(--font-rounded)" }}>
          <div style={{ width: 8, height: 8, borderRadius: "50%", background: "#fff" }}/> Record
        </button>
      </div>
    </div>
  );
}

// ---- Large (336×336) ----
function HomeLargeA({ pace = "yellow" }) {
  return (
    <div style={{ ...cardDark, width: 336, height: 336, padding: 20, display: "flex", flexDirection: "column", gap: 14 }}>
      <WHeader right={<span className="t-caption" style={{ fontSize: 11 }}>3:02 PM</span>}/>
      <div style={{ display: "flex", alignItems: "flex-end", justifyContent: "space-between" }}>
        <div>
          <div className="t-num" style={{ fontSize: 88, lineHeight: 0.85 }}>
            4<span style={{ fontWeight: 600, color: "var(--text-faint)", fontSize: 40 }}>/8</span>
          </div>
          <div style={{ fontSize: 12, color: "var(--text-dim)", fontWeight: 500, marginTop: 4 }}>clips today</div>
        </div>
        <div style={{ position: "relative" }}>
          <ProgressRing done={4} total={8} size={80} stroke={7} color={paceColor(pace)}/>
          <div style={{ position: "absolute", inset: 0, display: "grid", placeItems: "center", fontSize: 11, color: "var(--text-dim)", fontWeight: 600 }}>50%</div>
        </div>
      </div>
      <div>
        <CellStrip done={4} total={8} w={296} h={8} color={paceColor(pace)}/>
        <div style={{ display: "flex", justifyContent: "space-between", fontSize: 10, color: "var(--text-faint)", marginTop: 6 }}>
          <span>10 AM</span><span>now</span><span>10 PM</span>
        </div>
      </div>
      <div style={{ fontSize: 12, color: "var(--text-dim)" }}>next · <span style={{ color: "var(--text)" }}>3:15 PM</span> · in 13m</div>
      <div style={{ display: "grid", gridTemplateColumns: "2fr 1fr", gap: 8, marginTop: "auto" }}>
        <button style={{ background: "var(--record)", color: "#fff", border: "none", borderRadius: 14, padding: "14px", fontWeight: 600, fontSize: 15, display: "flex", alignItems: "center", justifyContent: "center", gap: 7, cursor: "pointer", fontFamily: "var(--font-rounded)" }}>
          <div style={{ width: 12, height: 12, borderRadius: "50%", background: "#fff" }}/> Record
        </button>
        <button style={{ background: "rgba(255,255,255,0.08)", color: "var(--text)", border: "none", borderRadius: 14, padding: "14px", fontWeight: 600, fontSize: 13, display: "flex", alignItems: "center", justifyContent: "center", gap: 6, cursor: "pointer", fontFamily: "var(--font-rounded)" }}>
          <IconBulb size={14} color="currentColor"/> Idea
        </button>
      </div>
    </div>
  );
}

function HomeLargeB({ pace = "yellow" }) {
  const slots = [0.06, 0.16, 0.28, 0.40, 0.58, 0.72, 0.86, 0.96];
  const nowPct = 0.42;
  return (
    <div style={{ ...cardDark, width: 336, height: 336, padding: 20, display: "flex", flexDirection: "column", gap: 14 }}>
      <WHeader right={<span className="t-caption" style={{ fontSize: 11 }}>TUE · 3:02 PM</span>}/>
      <div className="t-num" style={{ fontSize: 44, lineHeight: 1 }}>
        4 <span style={{ color: "var(--text-faint)", fontSize: 26, fontWeight: 600 }}>of 8</span>
      </div>
      <div style={{ position: "relative", height: 70, marginTop: 4 }}>
        <div style={{ position: "absolute", left: 0, right: 0, top: 34, height: 1, background: "rgba(255,255,255,0.1)" }}/>
        {slots.map((p, i) => (
          <div key={i} style={{
            position: "absolute", top: 28, left: `${p*100}%`, transform: "translateX(-50%)",
            width: 13, height: 13, borderRadius: "50%",
            background: i < 4 ? paceColor(pace) : "transparent",
            border: `1.5px solid ${i < 4 ? paceColor(pace) : "rgba(255,255,255,0.22)"}`,
          }}/>
        ))}
        <div style={{ position: "absolute", left: `${nowPct*100}%`, top: 6, width: 1, height: 60, background: "var(--record)", transform: "translateX(-50%)" }}/>
        <div style={{ position: "absolute", left: `${nowPct*100}%`, top: 0, transform: "translateX(-50%)", fontSize: 9, color: "var(--record)", fontWeight: 700, letterSpacing: "0.1em" }}>NOW</div>
        <div style={{ position: "absolute", left: 0, bottom: 0, fontSize: 10, color: "var(--text-faint)" }}>10 AM</div>
        <div style={{ position: "absolute", right: 0, bottom: 0, fontSize: 10, color: "var(--text-faint)" }}>10 PM</div>
      </div>
      <div style={{ fontSize: 12, color: "var(--text-dim)" }}>next · <span style={{ color: "var(--text)" }}>3:15 PM</span>, then 4:30, 6:00</div>
      <div style={{ display: "grid", gridTemplateColumns: "2fr 1fr", gap: 8, marginTop: "auto" }}>
        <button style={{ background: "var(--record)", color: "#fff", border: "none", borderRadius: 14, padding: "14px", fontWeight: 600, fontSize: 15, display: "flex", alignItems: "center", justifyContent: "center", gap: 7, cursor: "pointer", fontFamily: "var(--font-rounded)" }}>
          <div style={{ width: 12, height: 12, borderRadius: "50%", background: "#fff" }}/> Record
        </button>
        <button style={{ background: "rgba(255,255,255,0.08)", color: "var(--text)", border: "none", borderRadius: 14, padding: "14px", fontWeight: 600, fontSize: 13, display: "flex", alignItems: "center", justifyContent: "center", gap: 6, cursor: "pointer", fontFamily: "var(--font-rounded)" }}>
          <IconBulb size={14}/> Idea
        </button>
      </div>
    </div>
  );
}

function HomeLargeC({ pace = "yellow" }) {
  return (
    <div style={{ ...cardDark, width: 336, height: 336, padding: 20, display: "flex", flexDirection: "column", position: "relative" }}>
      <WHeader right={<span className="t-caption">3:02 PM</span>}/>
      <div className="t-num" style={{ fontSize: 220, lineHeight: 0.85, marginTop: -4 }}>4</div>
      <div className="t-num" style={{ fontSize: 26, color: "var(--text-faint)", fontWeight: 600, marginTop: -10 }}>out of 8</div>
      <div style={{ marginTop: 14 }}>
        <Dots done={4} total={8} size={10} gap={7} color={paceColor(pace)}/>
      </div>
      <div style={{ fontSize: 12, color: "var(--text-dim)", fontWeight: 500, marginTop: 12 }}>next · <span style={{ color: "var(--text)" }}>3:15 PM</span> · in 13m</div>
      <button style={{
        position: "absolute", right: 20, bottom: 20,
        background: "var(--record)", color: "#fff", border: "none",
        borderRadius: 14, padding: "12px 18px",
        fontWeight: 700, fontSize: 14, fontFamily: "var(--font-rounded)",
        display: "flex", alignItems: "center", gap: 7, cursor: "pointer",
      }}>
        <div style={{ width: 10, height: 10, borderRadius: "50%", background: "#fff" }}/> Record
      </button>
    </div>
  );
}

function HomeScreenInner() {
  const [small, setSmall] = React.useState("A");
  const [med, setMed] = React.useState("A");
  const [large, setLarge] = React.useState("A");
  const pace = "yellow";

  const smallMap = { A: <HomeSmallA pace={pace}/>, B: <HomeSmallB pace={pace}/>, C: <HomeSmallC pace={pace}/> };
  const medMap = { A: <HomeMedA pace={pace}/>, B: <HomeMedB pace={pace}/>, C: <HomeMedC pace={pace}/> };
  const largeMap = { A: <HomeLargeA pace={pace}/>, B: <HomeLargeB pace={pace}/>, C: <HomeLargeC pace={pace}/> };
  const opts = [{value:"A",label:"A"},{value:"B",label:"B"},{value:"C",label:"C"}];

  const Row = ({ title, caption, value, setValue, map }) => (
    <div>
      <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between", marginBottom: 14 }}>
        <div>
          <div className="t-title" style={{ fontSize: 18 }}>{title}</div>
          <div className="t-body" style={{ fontSize: 13, marginTop: 2 }}>{caption}</div>
        </div>
        <VariantToggle value={value} onChange={setValue} options={opts}/>
      </div>
      <div style={{ display: "grid", gridTemplateColumns: "repeat(3, 1fr)", gap: 14 }}>
        {["A","B","C"].map(k => (
          <Pedestal key={k} selected={value === k} onClick={() => setValue(k)}>
            {map[k]}
            <div className="t-caption" style={{ marginTop: 4 }}>Option {k}</div>
          </Pedestal>
        ))}
      </div>
    </div>
  );

  return (
    <div style={{ padding: 32, display: "flex", gap: 36, background: "var(--bg)", minHeight: 1100 }}>
      <div style={{ display: "flex", flexDirection: "column", gap: 12, alignItems: "center", flexShrink: 0 }}>
        <div className="t-eyebrow">In context</div>
        <HomeFrame>
          <div style={{ transform: "scale(0.68)", transformOrigin: "top center", marginBottom: -108, display: "flex", justifyContent: "center" }}>
            {largeMap[large]}
          </div>
          <div style={{ display: "flex", gap: 10, justifyContent: "center", transform: "scale(0.72)", transformOrigin: "top center" }}>
            {smallMap[small]}
            <div style={{ transform: "scale(0.5)", transformOrigin: "top left", width: 168, height: 156 }}>{medMap[med]}</div>
          </div>
        </HomeFrame>
      </div>
      <div style={{ flex: 1, display: "flex", flexDirection: "column", gap: 32 }}>
        <Row title="Small" caption="Glanceable — count, pace, one tap." value={small} setValue={setSmall} map={smallMap}/>
        <Row title="Medium" caption="Adds a Record button (iOS 17 interactive)." value={med} setValue={setMed} map={medMap}/>
        <Row title="Large" caption="Full day context + two actions." value={large} setValue={setLarge} map={largeMap}/>
      </div>
    </div>
  );
}

function HomeScreenArtboard() {
  return (
    <DCArtboard id="home-screen" label="Home Screen" width={1480} height={1140}>
      <HomeScreenInner/>
    </DCArtboard>
  );
}

Object.assign(window, { HomeScreenInner, HomeScreenArtboard });
