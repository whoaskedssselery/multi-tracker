import type { NextConfig } from 'next';

const config: NextConfig = {
  sassOptions: {
    // Auto-inject design tokens — component SCSS files need no manual @use
    additionalData: `@use "@/client/shared/styles/variables" as *; @use "@/client/shared/styles/mixins" as *;`,
  },
  experimental: {
    optimizePackageImports: ['lucide-react', 'recharts', 'framer-motion'],
  },
};

export default config;
