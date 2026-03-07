<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>RailFocus — Premium Focus Timer</title>
<link rel="preconnect" href="https://fonts.googleapis.com">
<link href="https://fonts.googleapis.com/css2?family=Playfair+Display:ital,wght@0,400;0,700;0,900;1,400&family=Crimson+Pro:ital,wght@0,300;0,400;0,600;1,300&family=JetBrains+Mono:wght@300;400&display=swap" rel="stylesheet">
<style>
  :root {
    --gold: #C9A84C;
    --gold-light: #E8C97A;
    --gold-dim: #7A6230;
    --cream: #F5EDD8;
    --cream-dark: #E8D9BB;
    --ink: #1A1208;
    --ink-mid: #2E2010;
    --ink-soft: #4A3820;
    --ruby: #8B2020;
    --teal: #1A4A4A;
    --steam: rgba(245, 237, 216, 0.06);
  }

  * { margin: 0; padding: 0; box-sizing: border-box; }

  html { scroll-behavior: smooth; }

  body {
    background-color: var(--ink);
    color: var(--cream);
    font-family: 'Crimson Pro', Georgia, serif;
    font-size: 18px;
    line-height: 1.7;
    overflow-x: hidden;
  }

  /* ── NOISE TEXTURE OVERLAY ── */
  body::before {
    content: '';
    position: fixed;
    inset: 0;
    background-image: url("data:image/svg+xml,%3Csvg viewBox='0 0 256 256' xmlns='http://www.w3.org/2000/svg'%3E%3Cfilter id='noise'%3E%3CfeTurbulence type='fractalNoise' baseFrequency='0.9' numOctaves='4' stitchTiles='stitch'/%3E%3C/filter%3E%3Crect width='100%25' height='100%25' filter='url(%23noise)' opacity='0.04'/%3E%3C/svg%3E");
    pointer-events: none;
    z-index: 1000;
    opacity: 0.35;
  }

  /* ── HERO ── */
  .hero {
    min-height: 100vh;
    display: flex;
    flex-direction: column;
    align-items: center;
    justify-content: center;
    text-align: center;
    position: relative;
    padding: 80px 24px 60px;
    overflow: hidden;
  }

  /* Radial glow behind hero */
  .hero::after {
    content: '';
    position: absolute;
    top: 50%;
    left: 50%;
    transform: translate(-50%, -50%);
    width: 700px;
    height: 700px;
    background: radial-gradient(ellipse, rgba(201,168,76,0.12) 0%, transparent 70%);
    pointer-events: none;
  }

  /* Decorative track lines */
  .tracks {
    position: absolute;
    bottom: 0;
    left: 50%;
    transform: translateX(-50%);
    width: 120px;
    height: 200px;
    opacity: 0.3;
  }
  .track-line {
    position: absolute;
    bottom: 0;
    width: 3px;
    background: linear-gradient(to top, var(--gold), transparent);
    animation: track-grow 2.5s ease-out forwards;
  }
  .track-line:nth-child(1) { left: 36px; height: 0; animation-delay: 0.2s; }
  .track-line:nth-child(2) { left: 57px; height: 0; animation-delay: 0s; }
  .track-line:nth-child(3) { right: 36px; height: 0; animation-delay: 0.2s; }

  /* Track ties */
  .track-ties {
    position: absolute;
    bottom: 0;
    left: 0;
    right: 0;
    overflow: hidden;
    height: 190px;
  }
  .tie {
    position: absolute;
    left: 28px;
    right: 28px;
    height: 2px;
    background: var(--gold);
    opacity: 0;
    animation: tie-fade 0.3s ease forwards;
  }

  @keyframes track-grow { to { height: 190px; } }
  @keyframes tie-fade { to { opacity: 0.5; } }

  .hero-eyebrow {
    font-family: 'JetBrains Mono', monospace;
    font-size: 11px;
    letter-spacing: 0.3em;
    color: var(--gold);
    text-transform: uppercase;
    margin-bottom: 24px;
    opacity: 0;
    animation: fade-up 1s ease forwards 0.3s;
  }

  .hero-title {
    font-family: 'Playfair Display', serif;
    font-size: clamp(64px, 12vw, 120px);
    font-weight: 900;
    line-height: 0.9;
    letter-spacing: -0.02em;
    background: linear-gradient(170deg, var(--gold-light) 0%, var(--gold) 40%, var(--gold-dim) 100%);
    -webkit-background-clip: text;
    -webkit-text-fill-color: transparent;
    background-clip: text;
    opacity: 0;
    animation: fade-up 1s ease forwards 0.5s;
    position: relative;
    z-index: 1;
  }

  .hero-rule {
    width: 80px;
    height: 1px;
    background: linear-gradient(to right, transparent, var(--gold), transparent);
    margin: 28px auto;
    opacity: 0;
    animation: fade-up 1s ease forwards 0.7s;
  }

  .hero-subtitle {
    font-style: italic;
    font-size: clamp(18px, 3vw, 26px);
    color: var(--cream-dark);
    max-width: 560px;
    opacity: 0;
    animation: fade-up 1s ease forwards 0.9s;
    font-weight: 300;
  }

  .hero-badges {
    display: flex;
    flex-wrap: wrap;
    justify-content: center;
    gap: 12px;
    margin-top: 40px;
    opacity: 0;
    animation: fade-up 1s ease forwards 1.1s;
  }

  .badge {
    font-family: 'JetBrains Mono', monospace;
    font-size: 10px;
    letter-spacing: 0.15em;
    text-transform: uppercase;
    padding: 6px 14px;
    border: 1px solid var(--gold-dim);
    color: var(--gold);
    background: rgba(201,168,76,0.07);
    position: relative;
    overflow: hidden;
    transition: all 0.3s ease;
  }
  .badge::before {
    content: '';
    position: absolute;
    inset: 0;
    background: var(--gold);
    transform: translateX(-101%);
    transition: transform 0.3s ease;
    z-index: -1;
  }
  .badge:hover { color: var(--ink); border-color: var(--gold); }
  .badge:hover::before { transform: translateX(0); }

  .scroll-hint {
    position: absolute;
    bottom: 32px;
    left: 50%;
    transform: translateX(-50%);
    opacity: 0;
    animation: fade-up 1s ease forwards 1.5s;
    display: flex;
    flex-direction: column;
    align-items: center;
    gap: 8px;
  }
  .scroll-hint span {
    font-family: 'JetBrains Mono', monospace;
    font-size: 9px;
    letter-spacing: 0.3em;
    color: var(--gold-dim);
    text-transform: uppercase;
  }
  .scroll-dot {
    width: 1px;
    height: 36px;
    background: linear-gradient(to bottom, var(--gold-dim), transparent);
    animation: scroll-pulse 2s ease-in-out infinite;
  }
  @keyframes scroll-pulse {
    0%, 100% { opacity: 0.3; transform: scaleY(1); }
    50% { opacity: 1; transform: scaleY(1.2); }
  }

  @keyframes fade-up {
    from { opacity: 0; transform: translateY(20px); }
    to { opacity: 1; transform: translateY(0); }
  }

  /* ── SECTION WRAPPER ── */
  .section {
    max-width: 900px;
    margin: 0 auto;
    padding: 80px 32px;
    position: relative;
  }

  .section-label {
    font-family: 'JetBrains Mono', monospace;
    font-size: 10px;
    letter-spacing: 0.35em;
    color: var(--gold);
    text-transform: uppercase;
    margin-bottom: 12px;
    display: flex;
    align-items: center;
    gap: 12px;
  }
  .section-label::after {
    content: '';
    flex: 1;
    height: 1px;
    background: linear-gradient(to right, var(--gold-dim), transparent);
  }

  h2 {
    font-family: 'Playfair Display', serif;
    font-size: clamp(32px, 5vw, 52px);
    font-weight: 700;
    line-height: 1.1;
    color: var(--cream);
    margin-bottom: 32px;
  }

  h2 em {
    font-style: italic;
    color: var(--gold-light);
  }

  /* ── DIVIDER ── */
  .ornament-divider {
    display: flex;
    align-items: center;
    justify-content: center;
    gap: 16px;
    padding: 20px 0;
    opacity: 0.5;
  }
  .ornament-divider span { color: var(--gold); font-size: 14px; }
  .ornament-divider::before,
  .ornament-divider::after {
    content: '';
    flex: 1;
    height: 1px;
    background: linear-gradient(to right, transparent, var(--gold-dim));
  }
  .ornament-divider::after { background: linear-gradient(to left, transparent, var(--gold-dim)); }

  /* ── FEATURES GRID ── */
  .features-grid {
    display: grid;
    grid-template-columns: repeat(auto-fill, minmax(280px, 1fr));
    gap: 2px;
    margin-top: 8px;
    background: var(--gold-dim);
    border: 1px solid var(--gold-dim);
  }

  .feature-card {
    background: var(--ink-mid);
    padding: 32px 28px;
    transition: background 0.3s ease;
    position: relative;
    overflow: hidden;
  }
  .feature-card::before {
    content: '';
    position: absolute;
    top: 0;
    left: 0;
    right: 0;
    height: 2px;
    background: linear-gradient(to right, transparent, var(--gold), transparent);
    transform: scaleX(0);
    transition: transform 0.4s ease;
  }
  .feature-card:hover { background: var(--ink-soft); }
  .feature-card:hover::before { transform: scaleX(1); }

  .feature-icon {
    font-size: 28px;
    margin-bottom: 16px;
    display: block;
    filter: drop-shadow(0 0 8px rgba(201,168,76,0.4));
  }
  .feature-title {
    font-family: 'Playfair Display', serif;
    font-size: 20px;
    color: var(--gold-light);
    margin-bottom: 10px;
    font-weight: 700;
  }
  .feature-desc {
    font-size: 16px;
    color: rgba(245,237,216,0.65);
    line-height: 1.6;
    font-weight: 300;
  }

  /* ── SCREENSHOTS SECTION ── */
  .screenshots-grid {
    display: grid;
    grid-template-columns: repeat(3, 1fr);
    gap: 20px;
    margin-top: 16px;
  }

  .screenshot-frame {
    aspect-ratio: 9/19.5;
    background: var(--ink-mid);
    border: 1px solid var(--gold-dim);
    display: flex;
    flex-direction: column;
    align-items: center;
    justify-content: flex-end;
    padding-bottom: 20px;
    position: relative;
    overflow: hidden;
    transition: transform 0.4s ease, border-color 0.4s ease;
  }
  .screenshot-frame:hover {
    transform: translateY(-6px);
    border-color: var(--gold);
  }
  /* Fake phone UI sketch inside frame */
  .screenshot-frame::before {
    content: '';
    position: absolute;
    inset: 0;
    background: 
      radial-gradient(ellipse at 50% 30%, rgba(201,168,76,0.08) 0%, transparent 60%),
      repeating-linear-gradient(
        0deg,
        transparent,
        transparent 40px,
        rgba(201,168,76,0.03) 40px,
        rgba(201,168,76,0.03) 41px
      );
  }
  .screenshot-placeholder {
    width: 48px;
    height: 2px;
    background: var(--gold-dim);
    opacity: 0.6;
    border-radius: 99px;
  }
  .screenshot-label {
    font-family: 'JetBrains Mono', monospace;
    font-size: 9px;
    letter-spacing: 0.2em;
    color: var(--gold-dim);
    text-transform: uppercase;
    text-align: center;
    margin-top: 12px;
    position: relative;
    z-index: 1;
  }
  .screenshot-icon {
    font-size: 40px;
    position: absolute;
    top: 50%;
    left: 50%;
    transform: translate(-50%, -60%);
    opacity: 0.15;
  }

  /* ── TECH STACK ── */
  .tech-row {
    display: flex;
    flex-wrap: wrap;
    gap: 12px;
    margin-top: 8px;
  }

  .tech-pill {
    font-family: 'JetBrains Mono', monospace;
    font-size: 12px;
    padding: 8px 18px;
    border: 1px solid var(--gold-dim);
    color: var(--cream-dark);
    background: transparent;
    position: relative;
    transition: all 0.25s ease;
    cursor: default;
  }
  .tech-pill:hover {
    border-color: var(--gold);
    color: var(--gold-light);
    background: rgba(201,168,76,0.06);
  }
  .tech-pill .tech-dot {
    display: inline-block;
    width: 6px;
    height: 6px;
    border-radius: 50%;
    background: var(--gold);
    margin-right: 8px;
    vertical-align: middle;
    animation: pulse-dot 2s ease-in-out infinite;
  }
  @keyframes pulse-dot {
    0%, 100% { opacity: 1; }
    50% { opacity: 0.3; }
  }

  /* ── GETTING STARTED ── */
  .steps {
    counter-reset: step-counter;
    display: flex;
    flex-direction: column;
    gap: 0;
  }

  .step {
    display: grid;
    grid-template-columns: 48px 1fr;
    gap: 24px;
    padding: 28px 0;
    border-bottom: 1px solid rgba(201,168,76,0.12);
    counter-increment: step-counter;
    align-items: start;
  }
  .step:last-child { border-bottom: none; }

  .step-num {
    font-family: 'Playfair Display', serif;
    font-size: 36px;
    font-weight: 900;
    color: var(--gold-dim);
    line-height: 1;
    padding-top: 4px;
    font-style: italic;
  }

  .step-title {
    font-family: 'Playfair Display', serif;
    font-size: 20px;
    color: var(--gold-light);
    margin-bottom: 8px;
  }
  .step-desc {
    font-size: 16px;
    color: rgba(245,237,216,0.6);
    font-weight: 300;
    margin-bottom: 12px;
  }

  pre {
    background: rgba(0,0,0,0.4);
    border: 1px solid rgba(201,168,76,0.15);
    border-left: 2px solid var(--gold-dim);
    padding: 14px 18px;
    font-family: 'JetBrains Mono', monospace;
    font-size: 13px;
    color: var(--gold-light);
    overflow-x: auto;
    line-height: 1.7;
  }

  pre .comment { color: var(--gold-dim); }
  pre .cmd { color: var(--cream-dark); }

  /* ── PREREQS ── */
  .prereqs {
    display: flex;
    flex-direction: column;
    gap: 8px;
    margin-top: 4px;
  }
  .prereq {
    display: flex;
    align-items: center;
    gap: 14px;
    padding: 12px 16px;
    border: 1px solid rgba(201,168,76,0.15);
    background: rgba(201,168,76,0.03);
    font-family: 'JetBrains Mono', monospace;
    font-size: 13px;
    color: var(--cream-dark);
    transition: border-color 0.2s;
  }
  .prereq:hover { border-color: var(--gold-dim); }
  .prereq-check { color: var(--gold); font-size: 14px; }
  .prereq-version { margin-left: auto; color: var(--gold-dim); font-size: 11px; }

  /* ── CALLOUT ── */
  .callout {
    background: rgba(139,32,32,0.15);
    border: 1px solid rgba(139,32,32,0.4);
    border-left: 3px solid var(--ruby);
    padding: 16px 20px;
    font-size: 15px;
    color: rgba(245,237,216,0.75);
    margin: 16px 0;
  }
  .callout strong { color: #E88080; }

  /* ── LICENSE / FOOTER ── */
  .footer {
    border-top: 1px solid rgba(201,168,76,0.15);
    padding: 48px 32px;
    text-align: center;
    max-width: 900px;
    margin: 0 auto;
  }

  .footer-title {
    font-family: 'Playfair Display', serif;
    font-size: 36px;
    font-style: italic;
    color: var(--gold);
    margin-bottom: 12px;
    font-weight: 400;
  }

  .footer-sub {
    font-size: 16px;
    color: rgba(245,237,216,0.4);
    font-weight: 300;
    letter-spacing: 0.05em;
  }

  .footer-ornament {
    font-size: 32px;
    margin: 24px 0;
    opacity: 0.4;
    letter-spacing: 0.3em;
  }

  /* ── LINK ── */
  a { color: var(--gold); text-decoration: none; border-bottom: 1px solid var(--gold-dim); transition: border-color 0.2s; }
  a:hover { border-color: var(--gold); }

  /* Animate sections on scroll */
  .reveal {
    opacity: 0;
    transform: translateY(30px);
    transition: opacity 0.8s ease, transform 0.8s ease;
  }
  .reveal.visible {
    opacity: 1;
    transform: none;
  }
</style>
</head>
<body>

<!-- ══════════════ HERO ══════════════ -->
<section class="hero">
  <p class="hero-eyebrow">✦ Platform — iOS · Android · macOS ✦</p>
  <h1 class="hero-title">RailFocus</h1>
  <div class="hero-rule"></div>
  <p class="hero-subtitle">A premium, train-journey-themed focus and productivity timer. All aboard.</p>
  <div class="hero-badges">
    <span class="badge">Flutter</span>
    <span class="badge">Firebase</span>
    <span class="badge">Hive Local DB</span>
    <span class="badge">Open Source</span>
    <span class="badge">MIT License</span>
  </div>

  <!-- SVG train tracks -->
  <svg class="tracks" viewBox="0 0 120 200" fill="none" xmlns="http://www.w3.org/2000/svg">
    <line x1="36" y1="200" x2="20" y2="0" stroke="url(#g1)" stroke-width="2.5"/>
    <line x1="57" y1="200" x2="57" y2="0" stroke="url(#g1)" stroke-width="2.5"/>
    <line x1="78" y1="200" x2="94" y2="0" stroke="url(#g1)" stroke-width="2.5"/>
    <!-- ties -->
    <line x1="32" y1="180" x2="82" y2="180" stroke="#7A6230" stroke-width="1.5" opacity="0.7"/>
    <line x1="31" y1="155" x2="83" y2="155" stroke="#7A6230" stroke-width="1.5" opacity="0.6"/>
    <line x1="30" y1="130" x2="84" y2="130" stroke="#7A6230" stroke-width="1.5" opacity="0.5"/>
    <line x1="28" y1="105" x2="86" y2="105" stroke="#7A6230" stroke-width="1.5" opacity="0.4"/>
    <line x1="26" y1="80" x2="88" y2="80" stroke="#7A6230" stroke-width="1.5" opacity="0.3"/>
    <line x1="24" y1="55" x2="90" y2="55" stroke="#7A6230" stroke-width="1.5" opacity="0.2"/>
    <line x1="22" y1="30" x2="92" y2="30" stroke="#7A6230" stroke-width="1.5" opacity="0.1"/>
    <defs>
      <linearGradient id="g1" x1="0" y1="0" x2="0" y2="1" gradientUnits="objectBoundingBox">
        <stop offset="0" stop-color="#C9A84C" stop-opacity="0"/>
        <stop offset="0.5" stop-color="#C9A84C" stop-opacity="0.6"/>
        <stop offset="1" stop-color="#C9A84C" stop-opacity="0.9"/>
      </linearGradient>
    </defs>
  </svg>

  <div class="scroll-hint">
    <span>Scroll</span>
    <div class="scroll-dot"></div>
  </div>
</section>

<div class="ornament-divider"><span>✦ ✦ ✦</span></div>

<!-- ══════════════ FEATURES ══════════════ -->
<section class="section reveal">
  <p class="section-label">✦ What Awaits</p>
  <h2>An <em>immersive</em> journey<br>for focused minds</h2>

  <div class="features-grid">
    <div class="feature-card">
      <span class="feature-icon">🌅</span>
      <div class="feature-title">Dynamic Scenery</div>
      <p class="feature-desc">A stunning art-deco diorama that transforms with your real-world time of day — morning sunrises, twilight fireflies, midnight shooting stars, and the aurora borealis.</p>
    </div>
    <div class="feature-card">
      <span class="feature-icon">⏱️</span>
      <div class="feature-title">Deep Work Timer</div>
      <p class="feature-desc">A fully customisable focus timer that functions as your train journey. Arrive at your destination safely, distraction-free and on schedule.</p>
    </div>
    <div class="feature-card">
      <span class="feature-icon">🏆</span>
      <div class="feature-title">Gamification & Progression</div>
      <p class="feature-desc">Build your Grand Station brick by brick. Earn streaks to unlock Focus Moods, complete Daily Challenges, and unlock gorgeous scenic routes with accumulated focus hours.</p>
    </div>
    <div class="feature-card">
      <span class="feature-icon">🤝</span>
      <div class="feature-title">Co-working Cabins</div>
      <p class="feature-desc">Start or join real-time focus rooms. Study and work alongside friends with perfectly synchronised timers — your own shared cabin on the express.</p>
    </div>
    <div class="feature-card">
      <span class="feature-icon">🎵</span>
      <div class="feature-title">Ambient Soundscapes</div>
      <p class="feature-desc">A built-in audio mixer with high-quality ambient tracks — Rain, Tracks, Lo-Fi, Sleep — to keep you perfectly zoned in at every hour.</p>
    </div>
    <div class="feature-card">
      <span class="feature-icon">☁️</span>
      <div class="feature-title">Cloud Sync & Offline</div>
      <p class="feature-desc">All achievements and focus hours sync seamlessly via Firebase. An offline-first architecture via Hive means you're never left waiting at the platform.</p>
    </div>
  </div>
</section>

<div class="ornament-divider"><span>✦</span></div>

<!-- ══════════════ SCREENSHOTS ══════════════ -->
<section class="section reveal">
  <p class="section-label">✦ The Carriages</p>
  <h2>Every screen, <em>crafted</em><br>with intention</h2>

  <div class="screenshots-grid">
    <div class="screenshot-frame">
      <span class="screenshot-icon">🚉</span>
      <div class="screenshot-placeholder"></div>
      <p class="screenshot-label">The Departure Hall</p>
    </div>
    <div class="screenshot-frame">
      <span class="screenshot-icon">🎫</span>
      <div class="screenshot-placeholder"></div>
      <p class="screenshot-label">Cabin Selection</p>
    </div>
    <div class="screenshot-frame">
      <span class="screenshot-icon">🚂</span>
      <div class="screenshot-placeholder"></div>
      <p class="screenshot-label">Active Focus Journey</p>
    </div>
  </div>
  <p style="margin-top:20px; font-size:14px; color: var(--gold-dim); font-style:italic; text-align:center;">Replace placeholder frames with actual screenshots or GIFs.</p>
</section>

<div class="ornament-divider"><span>✦</span></div>

<!-- ══════════════ GETTING STARTED ══════════════ -->
<section class="section reveal">
  <p class="section-label">✦ Boarding Pass</p>
  <h2>Getting <em>started</em></h2>

  <h3 style="font-family:'Playfair Display',serif; font-size:22px; color:var(--cream-dark); margin-bottom:16px; font-weight:400;">Prerequisites</h3>
  <div class="prereqs">
    <div class="prereq">
      <span class="prereq-check">◆</span>
      Flutter SDK
      <span class="prereq-version">v3.7.0 or higher</span>
    </div>
    <div class="prereq">
      <span class="prereq-check">◆</span>
      Dart SDK
      <span class="prereq-version">v3.1.0 or higher</span>
    </div>
    <div class="prereq">
      <span class="prereq-check">◆</span>
      Android Studio / Xcode
      <span class="prereq-version">for emulation &amp; builds</span>
    </div>
  </div>

  <div style="margin-top: 48px;">
    <h3 style="font-family:'Playfair Display',serif; font-size:22px; color:var(--cream-dark); margin-bottom:8px; font-weight:400;">Installation</h3>
    <div class="steps">

      <div class="step">
        <div class="step-num">1</div>
        <div>
          <div class="step-title">Clone the Repository</div>
          <pre><span class="comment"># Clone and enter the project</span>
<span class="cmd">git clone https://github.com/your-username/RailFocus.git
cd RailFocus</span></pre>
        </div>
      </div>

      <div class="step">
        <div class="step-num">2</div>
        <div>
          <div class="step-title">Setup Firebase</div>
          <div class="callout">
            <strong>⚠ Security Note:</strong> You will need to create your own Firebase project. Never commit <code>google-services.json</code> or <code>GoogleService-Info.plist</code> to version control.
          </div>
          <p class="step-desc">Create a project in the <a href="https://console.firebase.google.com/">Firebase Console</a>, add Android and iOS apps, then enable <strong>Authentication</strong> (Google &amp; Email/Password) and <strong>Firestore Database</strong>. Place the config files at:</p>
          <pre><span class="comment"># Android</span>
<span class="cmd">android/app/google-services.json</span>

<span class="comment"># iOS</span>
<span class="cmd">ios/Runner/GoogleService-Info.plist</span></pre>
        </div>
      </div>

      <div class="step">
        <div class="step-num">3</div>
        <div>
          <div class="step-title">Install Dependencies</div>
          <pre><span class="cmd">flutter pub get</span></pre>
        </div>
      </div>

      <div class="step">
        <div class="step-num">4</div>
        <div>
          <div class="step-title">Run the App</div>
          <p class="step-desc">Select your emulator or physical device, then run:</p>
          <pre><span class="cmd">flutter run</span>

<span class="comment"># For a specific device</span>
<span class="cmd">flutter run -d &lt;device-id&gt;</span></pre>
        </div>
      </div>

    </div>
  </div>
</section>

<div class="ornament-divider"><span>✦</span></div>

<!-- ══════════════ TECH STACK ══════════════ -->
<section class="section reveal">
  <p class="section-label">✦ The Engine Room</p>
  <h2>Tech stack &amp; <em>architecture</em></h2>

  <p style="font-size:17px; color:rgba(245,237,216,0.65); font-weight:300; max-width:600px; margin-bottom:28px;">Built for performance and elegance. Pure <code>StatefulWidget</code> mechanics with isolated singleton services eliminate unnecessary rebuilds, ensuring the UI is always silky smooth.</p>

  <div class="tech-row">
    <span class="tech-pill"><span class="tech-dot"></span>Flutter (Dart)</span>
    <span class="tech-pill"><span class="tech-dot"></span>Firebase Auth</span>
    <span class="tech-pill"><span class="tech-dot"></span>Cloud Firestore</span>
    <span class="tech-pill"><span class="tech-dot"></span>Hive NoSQL</span>
    <span class="tech-pill"><span class="tech-dot"></span>go_router</span>
    <span class="tech-pill"><span class="tech-dot"></span>flutter_animate</span>
    <span class="tech-pill"><span class="tech-dot"></span>CustomPainters</span>
    <span class="tech-pill"><span class="tech-dot"></span>Singleton Services</span>
  </div>

  <div style="margin-top:32px; display:grid; grid-template-columns:1fr 1fr; gap:16px;">
    <div style="padding:20px; border:1px solid rgba(201,168,76,0.15); background:rgba(201,168,76,0.03);">
      <div style="font-family:'JetBrains Mono',monospace; font-size:10px; letter-spacing:0.2em; color:var(--gold-dim); text-transform:uppercase; margin-bottom:10px;">Offline First</div>
      <p style="font-size:15px; color:rgba(245,237,216,0.6); font-weight:300;">Hive as the source of truth locally. Firebase as the cloud layer. Data always available, even without a connection.</p>
    </div>
    <div style="padding:20px; border:1px solid rgba(201,168,76,0.15); background:rgba(201,168,76,0.03);">
      <div style="font-family:'JetBrains Mono',monospace; font-size:10px; letter-spacing:0.2em; color:var(--gold-dim); text-transform:uppercase; margin-bottom:10px;">Performance</div>
      <p style="font-size:15px; color:rgba(245,237,216,0.6); font-weight:300;">Isolated singleton services prevent widget tree pollution. Spring physics and haptics feel physical and responsive.</p>
    </div>
  </div>
</section>

<div class="ornament-divider"><span>✦</span></div>

<!-- ══════════════ FOOTER ══════════════ -->
<footer class="footer reveal">
  <div class="footer-ornament">🚂</div>
  <div class="footer-title">All aboard.</div>
  <p class="footer-sub">Distributed under the MIT License · Made with ❤️ for focused minds</p>
</footer>

<script>
  // Intersection Observer for reveal animations
  const reveals = document.querySelectorAll('.reveal');
  const obs = new IntersectionObserver((entries) => {
    entries.forEach(e => {
      if (e.isIntersecting) {
        e.target.classList.add('visible');
        obs.unobserve(e.target);
      }
    });
  }, { threshold: 0.1, rootMargin: '0px 0px -60px 0px' });
  reveals.forEach(r => obs.observe(r));
</script>
</body>
</html>
