import { useEffect, useState } from 'react';
import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom';
import { Toaster } from 'react-hot-toast';
import { createClient } from '@/shared/lib/supabase/client';
import { useAppStore } from '@/shared/store';
import { AppShell } from '@/widgets/AppShell';
import { AuthForm } from '@/features/auth';

export function App() {
  return (
    <BrowserRouter>
      <Root />
    </BrowserRouter>
  );
}

function Root() {
  const [authed, setAuthed] = useState<boolean | null>(null);
  const themeMode = useAppStore(s => s.preferences.themeMode);

  // Theme — applies on every screen, including auth.
  useEffect(() => {
    const html = document.documentElement;
    const apply = (dark: boolean) => html.setAttribute('data-theme', dark ? 'dark' : 'light');
    if (themeMode === 'dark')  { apply(true);  return; }
    if (themeMode === 'light') { apply(false); return; }
    const mq = window.matchMedia('(prefers-color-scheme: dark)');
    apply(mq.matches);
    const h = (e: MediaQueryListEvent) => apply(e.matches);
    mq.addEventListener('change', h);
    return () => mq.removeEventListener('change', h);
  }, [themeMode]);

  // Auth session.
  useEffect(() => {
    const sb = createClient();
    sb.auth.getSession().then(({ data }) => setAuthed(!!data.session));
    const { data: sub } = sb.auth.onAuthStateChange((_e, session) => setAuthed(!!session));
    return () => sub.subscription.unsubscribe();
  }, []);

  if (authed === null) return <div style={{ height: '100dvh', background: 'var(--color-bg)' }} />;

  return (
    <>
      <Routes>
        <Route path="/auth" element={authed ? <Navigate to="/" replace /> : <AuthForm />} />
        <Route path="/*"    element={authed ? <AppShell /> : <Navigate to="/auth" replace />} />
      </Routes>
      <Toaster
        position="bottom-right"
        toastOptions={{
          duration: 3000,
          style: {
            fontFamily: "'Manrope', sans-serif",
            fontSize: '14px',
            borderRadius: '12px',
            padding: '12px 16px',
            background: 'var(--color-surface)',
            color: 'var(--color-text1)',
            border: '1px solid var(--color-border)',
          },
        }}
      />
    </>
  );
}
