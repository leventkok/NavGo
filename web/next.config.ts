import type { NextConfig } from "next";

const apiOrigin = process.env.NAVGO_API_PROXY_ORIGIN ?? "http://127.0.0.1:8080";

const nextConfig: NextConfig = {
  reactStrictMode: true,
  // Browser calls same-origin /navgo-api/* → avoids CORS / localhost vs 127.0.0.1 mismatch.
  async rewrites() {
    return [
      {
        source: "/navgo-api/:path*",
        destination: `${apiOrigin}/:path*`,
      },
    ];
  },
};

export default nextConfig;
