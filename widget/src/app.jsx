// Main app — assembles the design canvas with all four surfaces + intro

function IntroArtboard() {
  const Card = ({ tag, title, sub, priority, tint }) => (
    <div style={{
      background: "var(--bg-elev)",
      border: "1px solid var(--hairline)",
      borderRadius: 18, padding: 18, position: "relative",
      display: "flex", flexDirection: "column", gap: 8,
    }}>
      {priority && (
        <div style={{
          position: "absolute", top: 14, right: 14,
          background: "var(--record)", color: "#fff",
          padding: "3px 9px", borderRadius: 999,
          fontFamily: "var(--font-rounded)", fontWeight: 700, fontSize: 10,
          letterSpacing: "0.06em",
        }}>MVP</div>
      )}
      <div className="t-eyebrow" style={{ color: tint || "var(--text-faint)" }}>{tag}</div>
      <div className="t-title" style={{ fontSize: 22 }}>{title}</div>
      <div className="t-body" style={{ fontSize: 14 }}>{sub}</div>
    </div>
  );

  return (
    <DCArtboard id="intro" label="Overview · priorities + language" width={1480} height={620}>
      <div style={{ padding: "44px 56px", background: "var(--bg)", height: "100%", display: "flex", flexDirection: "column", gap: 28 }}>
        <div>
          <div className="t-eyebrow" style={{ marginBottom: 10 }}>VLOGNUDGE · WIDGET SURFACES</div>
          <div className="t-title" style={{ fontSize: 56, lineHeight: 1.02 }}>
            Four ambient surfaces,<br/>
            <span style={{ color: "var(--text-dim)" }}>one persistent reminder.</span>
          </div>
          <div className="t-body" style={{ fontSize: 17, maxWidth: 760, marginTop: 12 }}>
            Exploring layout, progress visualization, and pace-color usage across
            Lock Screen, Home Screen, StandBy and Live Activity. Toggle variants inline.
          </div>
        </div>

        <div style={{ display: "grid", gridTemplateColumns: "repeat(4, 1fr)", gap: 14 }}>
          <Card tag="PRIORITY 1" title="Live Activity" sub="Lock screen + Dynamic Island, all day. Updates live as you film." priority/>
          <Card tag="PRIORITY 2" title="Lock Screen widget" sub="Rect, circular, inline-above-clock. Peripheral-vision reminder."/>
          <Card tag="PRIORITY 3" title="Home Screen widget" sub="One-tap record. Small / medium / large. iOS 17 interactive."/>
          <Card tag="PRIORITY 4" title="StandBy" sub="Giant across-the-room count. Docked and charging. Informational."/>
        </div>

        <div style={{ marginTop: "auto", display: "flex", gap: 32, alignItems: "flex-end", flexWrap: "wrap" }}>
          <div>
            <div className="t-eyebrow" style={{ marginBottom: 8 }}>PACE · MUTED, NOT ALARMING</div>
            <div style={{ display: "flex", gap: 18, alignItems: "center" }}>
              {[
                { c: "var(--pace-green)", l: "on pace" },
                { c: "var(--pace-yellow)", l: "behind" },
                { c: "var(--pace-orange)", l: "well behind" },
              ].map(x => (
                <div key={x.l} style={{ display: "flex", alignItems: "center", gap: 8 }}>
                  <div style={{ width: 14, height: 14, borderRadius: "50%", background: x.c }}/>
                  <span style={{ fontSize: 14, color: "var(--text-dim)", fontWeight: 500 }}>{x.l}</span>
                </div>
              ))}
              <div style={{ display: "flex", alignItems: "center", gap: 8, marginLeft: 8 }}>
                <div style={{ width: 14, height: 14, borderRadius: "50%", border: "1.5px dashed rgba(229,57,53,0.5)" }}/>
                <span style={{ fontSize: 14, color: "var(--text-faint)", textDecoration: "line-through" }}>red</span>
                <span style={{ fontSize: 13, color: "var(--text-faint)" }}>— never. punishment breaks ADHD brains.</span>
              </div>
            </div>
          </div>
          <div style={{ marginLeft: "auto" }}>
            <div className="t-eyebrow" style={{ marginBottom: 8 }}>MOCK DATA</div>
            <div style={{ fontSize: 14, color: "var(--text-dim)", fontWeight: 500 }}>3:02 PM · 4 of 8 clips · next 3:15 PM · last 2h ago · yellow</div>
          </div>
        </div>
      </div>
    </DCArtboard>
  );
}

function App() {
  return (
    <DesignCanvas title="VlogNudge · Widget wireframes" subtitle="Lock · Home · StandBy · Live Activity">
      <DCSection id="overview" title="Overview">
        {IntroArtboard()}
      </DCSection>
      <DCSection id="live-activity-sec" title="Live Activity — MVP">
        {LiveActivityArtboard()}
      </DCSection>
      <DCSection id="lockscreen-sec" title="Lock Screen widgets">
        {LockScreenArtboard()}
      </DCSection>
      <DCSection id="homescreen-sec" title="Home Screen widgets">
        {HomeScreenArtboard()}
      </DCSection>
      <DCSection id="standby-sec" title="StandBy">
        {StandByArtboard()}
      </DCSection>
    </DesignCanvas>
  );
}

ReactDOM.createRoot(document.getElementById("root")).render(<App/>);
