export default function SecurityPage() {
  return (
    <main style={{ maxWidth: 720, margin: "0 auto", padding: "2rem 1rem", fontFamily: "Georgia, serif" }}>
      <h1>NavGo Trust Center</h1>
      <p>
        Security controls for NavGo are adapted from agentic AI security patterns
        (handshake/channel auth, least agency LLM tools, audit, rate limits, kill switch).
      </p>
      <h2>Controls</h2>
      <ul>
        <li>Device handshake → login → bind → blended JWT</li>
        <li>Channel-bound private routes under <code>/api/v1/c/&#123;channelId&#125;</code></li>
        <li>LLM kill switch via <code>LLM_KILL_SWITCH</code></li>
        <li>CI: govulncheck, gosec, gitleaks</li>
      </ul>
      <h2>Subprocessors</h2>
      <p>Render, Cloudflare, Google Maps, Hugging Face — see compliance vendors policy.</p>
      <p>
        <a href="/security/vulnerability-disclosure">Vulnerability disclosure</a>
        {" · "}
        <a href="/privacy">Privacy</a>
      </p>
    </main>
  );
}
