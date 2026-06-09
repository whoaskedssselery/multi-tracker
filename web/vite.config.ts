import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';
import path from 'node:path';

const src = path.resolve(__dirname, 'src');

export default defineConfig({
  plugins: [react()],
  resolve: {
    alias: { '@': src },
  },
  css: {
    preprocessorOptions: {
      scss: {
        loadPaths: [src],
        // Auto-inject design tokens into every stylesheet (entry files only;
        // partials pulled via @use are resolved by sass and skip this).
        additionalData: '@use "shared/styles/variables" as *; @use "shared/styles/mixins" as *;',
      },
    },
  },
  server: { port: 3000 },
});
