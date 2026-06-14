import { useEffect, useRef, useState } from 'react';
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

  // Scrollbar — show while scrolling or hovering near the right edge.
  // CSS transitions on ::webkit-scrollbar-thumb don't fire on class removal from parent,
  // so we use a separate .scrollbar-hiding class that carries a CSS keyframe animation.
  useEffect(() => {
    const EDGE = 60;
    const FADE_MS = 600;
    const hideTimers  = new WeakMap<Element, ReturnType<typeof setTimeout>>();
    const fadeTimers  = new WeakMap<Element, ReturnType<typeof setTimeout>>();
    let hovered: Element | null = null;

    const show = (el: Element, cls: 'is-scrolling' | 'scrollbar-hover') => {
      const ft = fadeTimers.get(el);
      if (ft) { clearTimeout(ft); fadeTimers.delete(el); }
      el.classList.remove('scrollbar-hiding');
      el.classList.add(cls);
    };

    const hide = (el: Element, cls: 'is-scrolling' | 'scrollbar-hover') => {
      el.classList.remove(cls);
      el.classList.add('scrollbar-hiding');
      const ft = setTimeout(() => el.classList.remove('scrollbar-hiding'), FADE_MS);
      fadeTimers.set(el, ft);
    };

    const onScroll = (e: Event) => {
      const el = e.target as Element;
      show(el, 'is-scrolling');
      const prev = hideTimers.get(el);
      if (prev) clearTimeout(prev);
      hideTimers.set(el, setTimeout(() => hide(el, 'is-scrolling'), 800));
    };

    const onMouseMove = (e: MouseEvent) => {
      if (hovered) { hide(hovered, 'scrollbar-hover'); hovered = null; }
      let node = (document.elementFromPoint(e.clientX, e.clientY) ??
                  document.elementFromPoint(e.clientX - EDGE, e.clientY)) as Element | null;
      while (node && node !== document.documentElement) {
        const oy = window.getComputedStyle(node).overflowY;
        if ((oy === 'auto' || oy === 'scroll') && node.scrollHeight > node.clientHeight + 1) {
          const rect = node.getBoundingClientRect();
          if (e.clientX >= rect.right - EDGE) {
            show(node, 'scrollbar-hover');
            hovered = node;
          }
          break;
        }
        node = node.parentElement;
      }
    };

    document.addEventListener('scroll', onScroll, { capture: true, passive: true });
    document.addEventListener('mousemove', onMouseMove, { passive: true });
    return () => {
      document.removeEventListener('scroll', onScroll, { capture: true });
      document.removeEventListener('mousemove', onMouseMove);
    };
  }, []);

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
