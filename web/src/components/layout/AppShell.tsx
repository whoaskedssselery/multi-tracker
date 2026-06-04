'use client';

import { useEffect } from 'react';
import { usePathname } from 'next/navigation';
import { Sidebar } from './Sidebar';
import { MobileNav } from './MobileNav';
import { useSync } from '@/lib/hooks/useSync';
import { useAppStore } from '@/store/app-store';
import s from './AppShell.module.scss';

export function AppShell({ children }: { children: React.ReactNode }) {
  useSync(); // boot sync on mount

  const preferences = useAppStore(st => st.preferences);

  // Apply theme
  useEffect(() => {
    const html = document.documentElement;
    const { themeMode } = preferences;
    if (themeMode === 'dark') {
      html.setAttribute('data-theme', 'dark');
    } else if (themeMode === 'light') {
      html.setAttribute('data-theme', 'light');
    } else {
      // system
      const mq = window.matchMedia('(prefers-color-scheme: dark)');
      html.setAttribute('data-theme', mq.matches ? 'dark' : 'light');
      const handler = (e: MediaQueryListEvent) =>
        html.setAttribute('data-theme', e.matches ? 'dark' : 'light');
      mq.addEventListener('change', handler);
      return () => mq.removeEventListener('change', handler);
    }
  }, [preferences.themeMode]);

  return (
    <div className={s.shell}>
      <Sidebar />
      <main className={s.main}>
        {children}
      </main>
      <MobileNav />
    </div>
  );
}
