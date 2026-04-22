// Live Activity — MVP rebuild
// Grounded in the spec: pinned on Lock Screen all day during active window,
// Dynamic Island compact + minimal + expanded, action intents (Record, Not now, Skip hour),
// pace color drifts green → yellow → orange (never red).

// ---------- shared bits ----------

const LA_COLORS = {
  green: "#6E8F6A",
  yellow: "#C7A45A",
  orange: "#C98A5A",
};

function dotsProgress(done, total, size, color, trackColor = "rgba(255,255,255,0.18)", gap = 4) {
  return (
    <div style={{ display: "inline-flex", gap, alignItems: "center" }}>
      {Array.from({ length: total }).map((_, i) => (
        <span key={i} style={{ width: size, height: size, borderRadius: "50%", background: i < done ? color : trackColor }}/>
      ))}
    </div>
  );
}

// A glass card tuned for sitting on a Lock-Screen-like background
const glassCard = {
  background: "rgba(20,20,22,0.78)",
  border: "1px solid rgba(255,255,255,0.08)",
  borderRadius: 22,
  backdropFilter: "blur(24px) saturate(160%)",
  WebkitBackdropFilter: "blur(24px) saturate(160%)",
  color: "#fff",
  fontFamily: "var(--font-rounded)",
};

// ---------- Lock Screen presentations ----------

// A · "The useful one" — matches spec: big count, next time + bar, record button
function LALockA({ pace, done, total, nextAt, minsToNext, reason }) {
  const c = LA_COLORS[pace];
  const pct = done / total;
  return (
    <div style={{ ...glassCard, width: 354, padding: "12px 14px 14px" }}>
      {/* header strip */}
      <div style={{ display: "flex", alignItems: "center", gap: 6, marginBottom: 10 }}>
        <div style={{ width: 14, height: 14, borderRadius: 4, background: "var(--record)", display: "grid", placeItems: "center" }}>
          <div style={{ width: 6, height: 6, borderRadius: "50%", background: "#fff" }}/>
        </div>
        <span style={{ fontSize: 11, fontWeight: 600, color: "rgba(255,255,255,0.6)", letterSpacing: "0.04em" }}>VLOGNUDGE</span>
        <span style={{ marginLeft: "auto", fontSize: 10, color: "rgba(255,255,255,0.45)", fontWeight: 500 }}>LIVE · 3:02 PM</span>
      </div>

      <div style={{ display: "flex", alignItems: "center", gap: 14 }}>
        {/* count block */}
        <div>
          <div style={{ fontSize: 44, fontWeight: 800, letterSpacing: "-0.035em", lineHeight: 0.9, color: "#fff", fontFeatureSettings: "'tnum'" }}>
            {done}<span style={{ color: "rgba(255,255,255,0.45)", fontWeight: 700 }}>/{total}</span>
          </div>
          <div style={{ fontSize: 10, color: "rgba(255,255,255,0.55)", fontWeight: 500, marginTop: 2, letterSpacing: "0.02em" }}>CLIPS TODAY</div>
        </div>

        {/* divider */}
        <div style={{ width: 1, alignSelf: "stretch", background: "rgba(255,255,255,0.1)" }}/>

        {/* next block */}
        <div style={{ flex: 1 }}>
          <div style={{ fontSize: 9, color: "rgba(255,255,255,0.5)", fontWeight: 600, letterSpacing: "0.14em" }}>NEXT NUDGE</div>
          <div style={{ fontSize: 22, fontWeight: 700, letterSpacing: "-0.02em", color: "#fff", lineHeight: 1.05, marginTop: 1 }}>{nextAt}</div>
          <div style={{ fontSize: 11, color: "rgba(255,255,255,0.58)", fontWeight: 500 }}>in {minsToNext}m · {reason}</div>
        </div>

        {/* action */}
        <button style={{
          background: "var(--record)", border: "none", width: 54, height: 54, borderRadius: "50%",
          display: "grid", placeItems: "center", cursor: "pointer",
          boxShadow: "0 0 0 3px rgba(229,57,53,0.16), 0 6px 14px rgba(229,57,53,0.28)",
        }}>
          <div style={{ width: 20, height: 20, borderRadius: "50%", background: "#fff" }}/>
        </button>
      </div>

      {/* progress bar */}
      <div style={{ marginTop: 12, height: 5, borderRadius: 3, background: "rgba(255,255,255,0.1)", position: "relative", overflow: "hidden" }}>
        <div style={{ position: "absolute", left: 0, top: 0, bottom: 0, width: `${pct*100}%`, background: c, borderRadius: 3 }}/>
      </div>

      {/* action row */}
      <div style={{ display: "flex", gap: 6, marginTop: 10 }}>
        <LAButton label="Record" primary/>
        <LAButton label="Not now"/>
        <LAButton label="Skip hour"/>
      </div>
    </div>
  );
}

function LAButton({ label, primary }) {
  return (
    <button style={{
      flex: 1, fontFamily: "var(--font-rounded)", fontSize: 11, fontWeight: 600,
      padding: "7px 8px", borderRadius: 10, cursor: "pointer",
      border: primary ? "none" : "1px solid rgba(255,255,255,0.12)",
      background: primary ? "rgba(229,57,53,0.9)" : "rgba(255,255,255,0.06)",
      color: "#fff", letterSpacing: "0.01em",
    }}>{label}</button>
  );
}

// B · "Prompt-forward" — leads with the topic prompt; count is secondary.
function LALockB({ pace, done, total, nextAt, minsToNext, prompt }) {
  const c = LA_COLORS[pace];
  return (
    <div style={{ ...glassCard, width: 354, padding: "12px 14px" }}>
      <div style={{ display: "flex", alignItems: "center", gap: 6, marginBottom: 8 }}>
        <div style={{ width: 14, height: 14, borderRadius: 4, background: "var(--record)", display: "grid", placeItems: "center" }}>
          <div style={{ width: 6, height: 6, borderRadius: "50%", background: "#fff" }}/>
        </div>
        <span style={{ fontSize: 11, fontWeight: 600, color: "rgba(255,255,255,0.6)" }}>VlogNudge</span>
        <span style={{ marginLeft: "auto", fontSize: 10, color: c, fontWeight: 600 }}>
          {dotsProgress(done, total, 5, c)}
        </span>
      </div>
      <div style={{ fontSize: 9, color: "rgba(255,255,255,0.5)", fontWeight: 600, letterSpacing: "0.14em", marginBottom: 2 }}>PROMPT · {nextAt}</div>
      <div style={{ fontSize: 16, fontWeight: 600, color: "#fff", lineHeight: 1.25, letterSpacing: "-0.01em" }}>
        {prompt}
      </div>
      <div style={{ display: "flex", alignItems: "center", gap: 8, marginTop: 10 }}>
        <button style={{
          background: "var(--record)", border: "none", borderRadius: 12,
          padding: "8px 14px", color: "#fff", fontWeight: 700, fontSize: 13,
          fontFamily: "var(--font-rounded)", display: "flex", alignItems: "center", gap: 6, cursor: "pointer",
        }}>
          <div style={{ width: 9, height: 9, borderRadius: "50%", background: "#fff" }}/>
          Record
        </button>
        <button style={{
          background: "rgba(255,255,255,0.06)", color: "#fff",
          border: "1px solid rgba(255,255,255,0.1)", borderRadius: 12,
          padding: "8px 12px", fontWeight: 600, fontSize: 12, fontFamily: "var(--font-rounded)", cursor: "pointer",
        }}>Not now</button>
        <span style={{ marginLeft: "auto", fontSize: 11, color: "rgba(255,255,255,0.55)", fontWeight: 500 }}>{done}/{total} · in {minsToNext}m</span>
      </div>
    </div>
  );
}

// C · "Minimal glass" — last-clip grounded, tiny; for users who want less.
function LALockC({ pace, done, total, nextAt, lastClip }) {
  const c = LA_COLORS[pace];
  const pct = done / total;
  return (
    <div style={{ ...glassCard, width: 354, padding: "10px 14px", display: "flex", alignItems: "center", gap: 12 }}>
      <div style={{ width: 14, height: 14, borderRadius: 4, background: "var(--record)", display: "grid", placeItems: "center", flexShrink: 0 }}>
        <div style={{ width: 6, height: 6, borderRadius: "50%", background: "#fff" }}/>
      </div>
      <div style={{ flex: 1, minWidth: 0 }}>
        <div style={{ display: "flex", alignItems: "baseline", gap: 6 }}>
          <span style={{ fontSize: 14, fontWeight: 700, color: "#fff" }}>{done}/{total}</span>
          <span style={{ fontSize: 11, color: "rgba(255,255,255,0.5)", fontWeight: 500 }}>· next {nextAt}</span>
        </div>
        <div style={{ marginTop: 4, height: 3, borderRadius: 2, background: "rgba(255,255,255,0.12)", position: "relative", overflow: "hidden" }}>
          <div style={{ position: "absolute", left: 0, top: 0, bottom: 0, width: `${pct*100}%`, background: c }}/>
        </div>
        <div style={{ fontSize: 10, color: "rgba(255,255,255,0.4)", marginTop: 3, fontWeight: 500 }}>last {lastClip}</div>
      </div>
      <button style={{
        background: "var(--record)", border: "none", width: 40, height: 40, borderRadius: "50%",
        display: "grid", placeItems: "center", cursor: "pointer",
      }}>
        <div style={{ width: 14, height: 14, borderRadius: "50%", background: "#fff" }}/>
      </button>
    </div>
  );
}

// ---------- Dynamic Island states ----------

function DICompact({ pace, done, total }) {
  const c = LA_COLORS[pace];
  return (
    <div style={{
      background: "#000", borderRadius: 999, padding: "5px 10px 5px 8px",
      display: "inline-flex", alignItems: "center", gap: 7, color: "#fff",
      height: 37, minWidth: 126, justifyContent: "space-between",
      fontFamily: "var(--font-rounded)", fontWeight: 700, fontSize: 14,
    }}>
      {/* record glyph on the leading side */}
      <div style={{ width: 14, height: 14, borderRadius: 3.5, background: c, display: "grid", placeItems: "center" }}>
        <div style={{ width: 6, height: 6, borderRadius: "50%", background: "#000" }}/>
      </div>
      {/* keep center clear for the camera cutout */}
      <div style={{ width: 28, height: 28, borderRadius: "50%", background: "transparent" }}/>
      {/* trailing count */}
      <span style={{ color: c, fontWeight: 800, fontFeatureSettings: "'tnum'" }}>{done}/{total}</span>
    </div>
  );
}

function DIMinimal({ pace }) {
  const c = LA_COLORS[pace];
  return (
    <div style={{ background: "#000", borderRadius: "50%", width: 38, height: 38, display: "grid", placeItems: "center" }}>
      <div style={{ width: 14, height: 14, borderRadius: 3.5, background: c, display: "grid", placeItems: "center" }}>
        <div style={{ width: 6, height: 6, borderRadius: "50%", background: "#000" }}/>
      </div>
    </div>
  );
}

// Expanded — four regions mirroring the spec (leading / trailing / center / bottom).
function DIExpanded({ pace, done, total, nextAt, minsToNext, prompt, recentClips }) {
  const c = LA_COLORS[pace];
  const pct = done / total;
  return (
    <div style={{
      background: "#000", borderRadius: 44, padding: "14px 18px 16px",
      color: "#fff", width: 370, fontFamily: "var(--font-rounded)",
      display: "flex", flexDirection: "column", gap: 12,
    }}>
      {/* top row (leading / camera cutout space / trailing) */}
      <div style={{ display: "grid", gridTemplateColumns: "1fr auto 1fr", alignItems: "start", gap: 14 }}>
        <div style={{ display: "flex", flexDirection: "column", gap: 1 }}>
          <div style={{ fontSize: 9, color: "rgba(255,255,255,0.45)", fontWeight: 600, letterSpacing: "0.14em" }}>TODAY</div>
          <div style={{ fontSize: 30, fontWeight: 800, letterSpacing: "-0.03em", color: "#fff", lineHeight: 1 }}>
            {done}<span style={{ color: "rgba(255,255,255,0.4)" }}>/{total}</span>
          </div>
        </div>
        {/* island camera cutout */}
        <div style={{ width: 42, height: 28, background: "#000" }}/>
        <div style={{ textAlign: "right" }}>
          <div style={{ fontSize: 9, color: "rgba(255,255,255,0.45)", fontWeight: 600, letterSpacing: "0.14em" }}>NEXT</div>
          <div style={{ fontSize: 20, fontWeight: 700, letterSpacing: "-0.02em", color: "#fff", lineHeight: 1 }}>{nextAt}</div>
          <div style={{ fontSize: 10, color: c, fontWeight: 600, marginTop: 2 }}>in {minsToNext}m</div>
        </div>
      </div>

      {/* center region — prompt (quiet) */}
      <div style={{
        background: "rgba(255,255,255,0.05)",
        border: "1px solid rgba(255,255,255,0.06)",
        borderRadius: 12, padding: "8px 12px",
      }}>
        <div style={{ fontSize: 9, color: "rgba(255,255,255,0.45)", fontWeight: 600, letterSpacing: "0.14em" }}>PROMPT</div>
        <div style={{ fontSize: 13, color: "#fff", fontWeight: 500, lineHeight: 1.3, marginTop: 1 }}>{prompt}</div>
      </div>

      {/* recent clips strip */}
      <div style={{ display: "flex", alignItems: "center", gap: 6 }}>
        {recentClips.map((t, i) => (
          <div key={i} style={{
            width: 34, height: 44, borderRadius: 7,
            background: "linear-gradient(180deg, rgba(255,255,255,0.1), rgba(255,255,255,0.02))",
            border: "1px solid rgba(255,255,255,0.06)",
            display: "flex", alignItems: "flex-end", padding: "2px 3px",
            fontSize: 8, fontWeight: 600, color: "rgba(255,255,255,0.6)",
          }}>{t}</div>
        ))}
        {Array.from({length: total - recentClips.length}).map((_, i) => (
          <div key={`e${i}`} style={{ width: 34, height: 44, borderRadius: 7, border: "1px dashed rgba(255,255,255,0.12)" }}/>
        ))}
      </div>

      {/* bottom region — progress + actions */}
      <div>
        <div style={{ height: 4, borderRadius: 2, background: "rgba(255,255,255,0.1)", overflow: "hidden" }}>
          <div style={{ width: `${pct*100}%`, height: "100%", background: c }}/>
        </div>
        <div style={{ display: "flex", gap: 7, marginTop: 10 }}>
          <LAButton label="Record" primary/>
          <LAButton label="Not now"/>
          <LAButton label="Skip hour"/>
        </div>
      </div>
    </div>
  );
}

// ---------- Phone frame ----------

function LockPhone({ children, pace, done, total }) {
  return (
    <div className="phone" style={{ width: 318 }}>
      <div className="phone-screen" style={{
        background: "linear-gradient(180deg, #11141f 0%, #1a121a 55%, #1d1013 100%)",
        display: "flex", flexDirection: "column", alignItems: "center", padding: "12px 14px 22px",
      }}>
        {/* camera cutout region — island shown compact */}
        <div style={{ marginTop: 4, marginBottom: 4 }}>
          <DICompact pace={pace} done={done} total={total}/>
        </div>

        {/* date + clock */}
        <div style={{ color: "rgba(255,255,255,0.72)", fontSize: 13, fontWeight: 500, marginTop: 18 }}>Tuesday, April 21</div>
        <div style={{ color: "#fff", fontSize: 80, fontWeight: 200, letterSpacing: "-0.04em", lineHeight: 1, fontFamily: "var(--font-rounded)" }}>3:02</div>

        {/* the live activity */}
        <div style={{ marginTop: 28, width: "100%", display: "flex", flexDirection: "column", alignItems: "center", gap: 10, flex: 1 }}>
          <div style={{ transform: "scale(0.9)", transformOrigin: "top center" }}>{children}</div>

          {/* a decorative second notification — a calendar row */}
          <div style={{
            width: 320, padding: "10px 14px",
            background: "rgba(255,255,255,0.06)",
            border: "1px solid rgba(255,255,255,0.04)",
            borderRadius: 18, color: "rgba(255,255,255,0.72)",
            fontSize: 11, fontWeight: 500, fontFamily: "var(--font-rounded)",
            transform: "scale(0.9)", transformOrigin: "top center",
          }}>
            Calendar · 1:00 PM · Lunch w/ Sam
          </div>
        </div>

        {/* bottom nav handles */}
        <div style={{ display: "flex", gap: 80, marginTop: "auto", paddingBottom: 6 }}>
          <div style={{ width: 40, height: 40, borderRadius: 20, background: "rgba(255,255,255,0.14)" }}/>
          <div style={{ width: 40, height: 40, borderRadius: 20, background: "rgba(255,255,255,0.14)" }}/>
        </div>
      </div>
    </div>
  );
}

// ---------- Main inner ----------

function LiveActivityInner() {
  const [variant, setVariant] = React.useState("A");
  const [pace, setPace] = React.useState("yellow");
  const [diState, setDiState] = React.useState("compact");

  const data = {
    done: 4, total: 8,
    nextAt: "3:15 PM", minsToNext: 13,
    reason: "long gap",
    lastClip: "1:12 PM · 2h ago",
    prompt: "Long gap — catch us up on the afternoon.",
    recentClips: ["10:14", "11:02", "12:08", "1:12"],
  };

  const lockEls = {
    A: <LALockA pace={pace} {...data}/>,
    B: <LALockB pace={pace} {...data}/>,
    C: <LALockC pace={pace} {...data}/>,
  };

  const diBg = "linear-gradient(180deg, #0d0d0f 0%, #1a1a1e 100%)";

  return (
    <div style={{ padding: "32px 40px", display: "flex", gap: 36, background: "var(--bg)", minHeight: 1120 }}>
      {/* LEFT: in context */}
      <div style={{ display: "flex", flexDirection: "column", alignItems: "center", gap: 12, flexShrink: 0 }}>
        <div className="t-eyebrow">In context · iPhone Lock Screen</div>
        <LockPhone pace={pace} done={data.done} total={data.total}>
          {lockEls[variant]}
        </LockPhone>
        <div className="t-body" style={{ fontSize: 12, maxWidth: 300, textAlign: "center" }}>
          Pinned all day during the active window (10 AM – 10 PM). Updates live as clips are filmed.
        </div>
      </div>

      {/* RIGHT: explorations */}
      <div style={{ flex: 1, display: "flex", flexDirection: "column", gap: 28 }}>
        {/* header */}
        <div style={{ display: "flex", justifyContent: "space-between", alignItems: "flex-end", gap: 16, flexWrap: "wrap" }}>
          <div>
            <div className="t-eyebrow" style={{ marginBottom: 2 }}>PRIORITY 1 · ACTIVITYKIT</div>
            <div className="t-title" style={{ fontSize: 28, lineHeight: 1.05 }}>Live Activity</div>
            <div className="t-body" style={{ fontSize: 14, marginTop: 4, maxWidth: 620 }}>
              One persistent surface on the Lock Screen and Dynamic Island, all day.
              Record, Not now, Skip hour — all app-intent buttons. Color drifts with pace; never red.
            </div>
          </div>
          <div style={{ display: "flex", flexDirection: "column", gap: 6, alignItems: "flex-end" }}>
            <div className="t-caption" style={{ fontSize: 11 }}>PACE STATE</div>
            <VariantToggle value={pace} onChange={setPace} options={[
              {value:"green", label:"On pace"},
              {value:"yellow", label:"Behind"},
              {value:"orange", label:"Well behind"},
            ]}/>
          </div>
        </div>

        {/* lock presentations */}
        <div>
          <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between", marginBottom: 12 }}>
            <div>
              <div className="t-title" style={{ fontSize: 17 }}>Lock Screen presentation</div>
              <div className="t-body" style={{ fontSize: 13, marginTop: 2 }}>
                Three directions — data-dense, prompt-forward, minimal.
              </div>
            </div>
            <VariantToggle value={variant} onChange={setVariant} options={[
              {value:"A", label:"A · Full"},
              {value:"B", label:"B · Prompt"},
              {value:"C", label:"C · Minimal"},
            ]}/>
          </div>

          <div style={{ display: "grid", gridTemplateColumns: "repeat(3, 1fr)", gap: 14 }}>
            {["A","B","C"].map(k => (
              <Pedestal key={k} selected={variant === k} onClick={() => setVariant(k)} style={{ padding: 18 }}>
                <div style={{ padding: 16, borderRadius: 20, background: "linear-gradient(180deg, #1a1420, #1d1016)", width: "100%", display: "flex", justifyContent: "center" }}>
                  <div style={{ transform: "scale(0.9)", transformOrigin: "center" }}>{lockEls[k]}</div>
                </div>
                <div style={{ display: "flex", gap: 8, width: "100%" }}>
                  <span className="t-caption">Option {k}</span>
                  <span className="t-body" style={{ fontSize: 12 }}>
                    {k === "A" && "Count · next · bar · 3 actions"}
                    {k === "B" && "Prompt leads, count secondary"}
                    {k === "C" && "One line + record"}
                  </span>
                </div>
              </Pedestal>
            ))}
          </div>
        </div>

        {/* Dynamic Island */}
        <div>
          <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between", marginBottom: 12 }}>
            <div>
              <div className="t-title" style={{ fontSize: 17 }}>Dynamic Island · three required states</div>
              <div className="t-body" style={{ fontSize: 13, marginTop: 2 }}>
                Compact during the active window. Minimal when sharing with another activity. Expanded on long-press.
              </div>
            </div>
            <VariantToggle value={diState} onChange={setDiState} options={[
              {value:"compact", label:"Compact"},
              {value:"minimal", label:"Minimal"},
              {value:"expanded", label:"Expanded"},
            ]}/>
          </div>

          <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr 1.9fr", gap: 14 }}>
            <Pedestal selected={diState==="compact"} onClick={() => setDiState("compact")} style={{ padding: 18 }}>
              <div style={{ background: diBg, borderRadius: 16, padding: "28px 20px", width: "100%", display: "flex", justifyContent: "center" }}>
                <DICompact pace={pace} done={data.done} total={data.total}/>
              </div>
              <div style={{ width: "100%" }}>
                <div className="t-caption">Compact</div>
                <div className="t-body" style={{ fontSize: 12 }}>Record glyph · count. Default in-window.</div>
              </div>
            </Pedestal>

            <Pedestal selected={diState==="minimal"} onClick={() => setDiState("minimal")} style={{ padding: 18 }}>
              <div style={{ background: diBg, borderRadius: 16, padding: "28px 20px", width: "100%", display: "flex", justifyContent: "center" }}>
                <DIMinimal pace={pace}/>
              </div>
              <div style={{ width: "100%" }}>
                <div className="t-caption">Minimal</div>
                <div className="t-body" style={{ fontSize: 12 }}>When another activity is active.</div>
              </div>
            </Pedestal>

            <Pedestal selected={diState==="expanded"} onClick={() => setDiState("expanded")} style={{ padding: 18 }}>
              <div style={{ background: diBg, borderRadius: 16, padding: "18px 16px", width: "100%", display: "flex", justifyContent: "center" }}>
                <div style={{ transform: "scale(0.85)", transformOrigin: "center top" }}>
                  <DIExpanded pace={pace} {...data}/>
                </div>
              </div>
              <div style={{ width: "100%" }}>
                <div className="t-caption">Expanded · long-press</div>
                <div className="t-body" style={{ fontSize: 12 }}>Four regions: count · next · prompt · strip + actions.</div>
              </div>
            </Pedestal>
          </div>
        </div>

        {/* lifecycle + rules */}
        <div style={{ display: "grid", gridTemplateColumns: "1.3fr 1fr", gap: 14 }}>
          <div className="surface-2" style={{ padding: 18 }}>
            <div className="t-eyebrow" style={{ marginBottom: 10 }}>LIFECYCLE</div>
            <div style={{ display: "grid", gridTemplateColumns: "auto 1fr", gap: "8px 14px", fontSize: 13, color: "var(--text-dim)", lineHeight: 1.45 }}>
              <span style={{ color: "var(--text)", fontWeight: 600 }}>10:00 AM</span><span>Window opens · Live Activity starts via <code style={{fontFamily:"var(--font-mono)",fontSize:12,color:"var(--text)"}}>ActivityKit</code> + <code style={{fontFamily:"var(--font-mono)",fontSize:12,color:"var(--text)"}}>BGTask</code>.</span>
              <span style={{ color: "var(--text)", fontWeight: 600 }}>Throughout</span><span>Updates on clip save, nudge fire, pace drift, and prompt change.</span>
              <span style={{ color: "var(--text)", fontWeight: 600 }}>~10 min pre-nudge</span><span>Dynamic Island compact softly pulses — pre-nudge tell.</span>
              <span style={{ color: "var(--text)", fontWeight: 600 }}>10:00 PM</span><span>Window closes · activity ends. Recap notification if opted in.</span>
            </div>
          </div>
          <div className="surface-2" style={{ padding: 18 }}>
            <div className="t-eyebrow" style={{ marginBottom: 10 }}>NEVER</div>
            <div style={{ display: "flex", flexDirection: "column", gap: 6, fontSize: 13, color: "var(--text-dim)", lineHeight: 1.4 }}>
              <div>· Never red. No streaks, no guilt copy.</div>
              <div>· No sound from the Live Activity itself.</div>
              <div>· No count-up counter — the tone stays calm.</div>
              <div>· Quiet hours + Focus modes suppress all visible change.</div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}

function LiveActivityArtboard() {
  return (
    <DCArtboard id="live-activity" label="Live Activity — MVP" width={1480} height={1120}>
      <LiveActivityInner/>
    </DCArtboard>
  );
}

Object.assign(window, { LiveActivityInner, LiveActivityArtboard });
