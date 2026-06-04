'use client';

import Link from 'next/link';
import { usePathname } from 'next/navigation';
import { motion } from 'framer-motion';
import {
  Home, Dumbbell, CheckSquare, Sparkles, Settings, RefreshCw,
} from 'lucide-react';
import { useAppStore } from '@/store/app-store';
import { formatSyncTime } from '@/lib/utils/format';
import { useSync } from '@/lib/hooks/useSync';
import s from './Sidebar.module.scss';

const NAV = [
  { href: '/',         icon: Home,        label: 'Главная' },
  { href: '/train',    icon: Dumbbell,    label: 'Тренировки' },
  { href: '/tasks',    icon: CheckSquare, label: 'Задачи' },
  { href: '/ai',       icon: Sparkles,    label: 'ИИ' },
];

export function Sidebar() {
  const pathname = usePathname();
  const sync = useAppStore(s => s.sync);
  const { syncNow } = useSync();

  const statusText = sync.busy
    ? (sync.status ?? 'Синхронизация…')
    : sync.lastSynced
      ? `Синхр. ${formatSyncTime(sync.lastSynced)}`
      : 'Готово к синхронизации';

  return (
    <aside className={s.sidebar}>
      {/* Brand */}
      <div className={s.brand}>
        <div className={s.brandIcon}>M</div>
        <span className={s.brandName}>Multi-tracker</span>
      </div>

      {/* Nav */}
      <nav className={s.nav}>
        {NAV.map(({ href, icon: Icon, label }) => {
          const active = href === '/' ? pathname === '/' : pathname.startsWith(href);
          return (
            <Link key={href} href={href} className={`${s.navItem} ${active ? s.navItemActive : ''}`}>
              {active && (
                <motion.span
                  className={s.navActiveBar}
                  layoutId="sidebar-active"
                  transition={{ type: 'spring', stiffness: 500, damping: 40 }}
                />
              )}
              <Icon size={18} className={s.navIcon} />
              <span className={s.navLabel}>{label}</span>
            </Link>
          );
        })}
      </nav>

      <div className={s.bottom}>
        {/* Sync status */}
        {sync.signedIn && (
          <button
            className={`${s.syncRow} ${sync.busy ? s.syncBusy : ''}`}
            onClick={syncNow}
            disabled={sync.busy}
            title="Синхронизировать сейчас"
          >
            <RefreshCw size={13} className={`${s.syncIcon} ${sync.busy ? s.syncSpin : ''}`} />
            <span className={s.syncText}>{statusText}</span>
          </button>
        )}
        {sync.error && <p className={s.syncError}>{sync.error}</p>}

        {/* Settings */}
        <Link
          href="/settings"
          className={`${s.navItem} ${pathname === '/settings' ? s.navItemActive : ''}`}
        >
          {pathname === '/settings' && (
            <motion.span className={s.navActiveBar} layoutId="sidebar-active"
              transition={{ type: 'spring', stiffness: 500, damping: 40 }} />
          )}
          <Settings size={18} className={s.navIcon} />
          <span className={s.navLabel}>Настройки</span>
        </Link>
      </div>
    </aside>
  );
}
