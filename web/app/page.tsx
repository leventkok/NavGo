"use client";

import Planner from "@/components/Planner";

export default function HomePage() {
  return (
    <main>
      <h1>NavGo</h1>
      <p className="lead">
        Tarayıcıda Gemma 2B intent çıkarır; mekanlar ve rota NavGo Go API’den
        grounded gelir.
      </p>
      <Planner />
    </main>
  );
}
