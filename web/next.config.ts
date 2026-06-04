import type { NextConfig } from 'next';

const config: NextConfig = {
  sassOptions: {
    additionalData: `@use "@/styles/variables" as *; @use "@/styles/mixins" as *;`,
  },
  experimental: {
    optimizePackageImports: ['lucide-react', 'recharts', 'framer-motion'],
  },
};

export default config;
