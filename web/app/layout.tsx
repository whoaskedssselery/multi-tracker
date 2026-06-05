import type { Metadata, Viewport } from 'next';
import Script from 'next/script';
import { Toaster } from 'react-hot-toast';
import { RouteShell } from '@frontend/widgets/RouteShell';
import './globals.scss';

export const metadata: Metadata = {
  title:       'Multi-tracker',
  description: 'Трекер веса, тренировок, задач и заметок',
  manifest:    '/manifest.json',

  // iPhone "Add to Home Screen" support
  appleWebApp: {
    capable:        true,
    title:          'Multi-tracker',
    statusBarStyle: 'default',
  },

  // Apple touch icon (180×180 recommended for iPhone)
  icons: {
    apple: '/icons/icon-180.png',
    icon:  '/icons/icon-192.png',
  },

  openGraph: {
    title:       'Multi-tracker',
    description: 'Трекер веса, тренировок, задач и заметок',
    type:        'website',
  },
};

export const viewport: Viewport = {
  // viewport-fit=cover: allows content under notch / Dynamic Island
  width:        'device-width',
  initialScale: 1,
  maximumScale: 1,
  viewportFit:  'cover',
  themeColor: [
    { media: '(prefers-color-scheme: light)', color: '#FAF7F0' },
    { media: '(prefers-color-scheme: dark)',  color: '#15130E' },
  ],
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="ru" suppressHydrationWarning>
      <head>
        <meta name="mobile-web-app-capable" content="yes" />
        <meta name="format-detection" content="telephone=no" />
      </head>
      <body>
        <RouteShell>{children}</RouteShell>

        <Toaster
          position="bottom-right"
          toastOptions={{
            duration: 3000,
            style: {
              fontFamily:   "'Manrope', sans-serif",
              fontSize:     '14px',
              borderRadius: '12px',
              padding:      '12px 16px',
            },
          }}
        />

        {/* Register service worker for PWA / offline support */}
        <Script id="sw-register" strategy="afterInteractive">{`
          if ('serviceWorker' in navigator) {
            window.addEventListener('load', () => {
              navigator.serviceWorker.register('/sw.js').catch(() => {});
            });
          }
        `}</Script>
      </body>
    </html>
  );
}
