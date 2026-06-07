import type { NextConfig } from 'next';
import path from 'node:path';

const srcDir = path.join(process.cwd(), 'src');

const config: NextConfig = {
  sassOptions: {
    // `src` on the load path lets SCSS resolve `shared/...` from anywhere.
    // Both keys provided to cover legacy (includePaths) and modern (loadPaths) sass APIs.
    includePaths: [srcDir],
    loadPaths: [srcDir],
    // Auto-inject design tokens — component SCSS needs no manual @use
    additionalData: `@use "shared/styles/variables" as *; @use "shared/styles/mixins" as *;`,
  },
  experimental: {
    optimizePackageImports: ['lucide-react', 'recharts', 'framer-motion'],
  },
};

export default config;
