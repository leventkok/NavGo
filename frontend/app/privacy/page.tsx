export default function PrivacyPage() {
  return (
    <main style={{ maxWidth: 720, margin: "0 auto", padding: "2rem 1rem", fontFamily: "Georgia, serif" }}>
      <h1>Privacy notice (starter)</h1>
      <p>
        NavGo processes account email, trip prompts, and itinerary data to provide planning features.
        Data is stored in the project Postgres instance and may be sent to the configured LLM upstream
        for intent/stop selection. Do not submit secrets in prompts.
      </p>
      <p>This is a starter notice — replace with counsel-reviewed language before production marketing.</p>
    </main>
  );
}
