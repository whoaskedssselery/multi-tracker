import type { NextConfig } from 'next';

const config: NextConfig = {
  sassOptions: {
    // Auto-inject design tokens into every SCSS module — no manual @use needed
    additionalData: `@use "@/shared/styles/variables" as *; @use "@/shared/styles/mixins" as *;`,
  },
  experimental: {
    optimizePackageImports: ['lucide-react', 'recharts', 'framer-motion'],
  },
};

export default config;
