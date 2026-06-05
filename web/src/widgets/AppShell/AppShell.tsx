'use client';

import { useEffect } from 'react';
import { Sidebar } from '@widgets/Sidebar';
import { MobileNav } from '@widgets/MobileNav';
import { useSync } from '@features/sync';
import { useAppStore } from '@shared/store';
import styles from './AppShell.module.scss';

export function AppShell({ children }: { children: React.ReactNode }) {
  useSync();

  const themeMode = useAppStore(s => s.preferences.themeMode);

  useEffect(() => {
    const html = document.documentElement;
    const apply = (dark: boolean) => html.setAttribute('data-theme', dark ? 'dark' : 'light');

    if (themeMode === 'dark')   { apply(true);  return; }
    if (themeMode === 'light')  { apply(false); return; }

    const mq = window.matchMedia('(prefers-color-scheme: dark)');
    apply(mq.matches);
    const h = (e: MediaQueryListEvent) => apply(e.matches);
    mq.addEventListener('change', h);
    return () => mq.removeEventListener('change', h);
  }, [themeMode]);

  return (
    <div className={styles.shell}>
      <Sidebar />
      <main className={styles.main}>{children}</main>
      <MobileNav />
    </div>
  );
}
