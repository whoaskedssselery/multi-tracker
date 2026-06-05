'use client';

import Link from 'next/link';
import { usePathname } from 'next/navigation';
import { motion } from 'framer-motion';
import { Home, Dumbbell, CheckSquare, Sparkles, Settings, RefreshCw } from 'lucide-react';
import { useAppStore } from '@frontend/shared/store';
import { useSync } from '@frontend/features/sync';
import { formatSyncTime } from '@frontend/shared/lib/utils/format';
import styles from './Sidebar.module.scss';

const NAV = [
  { href: '/',         icon: Home,        label: 'Главная' },
  { href: '/train',    icon: Dumbbell,    label: 'Тренировки' },
  { href: '/tasks',    icon: CheckSquare, label: 'Задачи' },
  { href: '/ai',       icon: Sparkles,    label: 'ИИ' },
];

export function Sidebar() {
  const pathname = usePathname();
  const sync     = useAppStore(s => s.sync);
  const { syncNow } = useSync();

  const status = sync.busy
    ? (sync.status ?? 'Синхронизация…')
    : sync.lastSynced
      ? `Синхр. ${formatSyncTime(sync.lastSynced)}`
      : 'Готово к синхронизации';

  const isActive = (href: string) =>
    href === '/' ? pathname === '/' : pathname.startsWith(href);

  return (
    <aside className={styles.sidebar}>
      <div className={styles.brand}>
        <div className={styles.brandIcon}>M</div>
        <span className={styles.brandName}>Multi-tracker</span>
      </div>

      <nav className={styles.nav}>
        {NAV.map(({ href, icon: Icon, label }) => (
          <Link key={href} href={href}
            className={`${styles.item} ${isActive(href) ? styles.itemActive : ''}`}>
            {isActive(href) && (
              <motion.span className={styles.indicator} layoutId="sidebar-active"
                transition={{ type: 'spring', stiffness: 500, damping: 40 }} />
            )}
            <Icon size={18} className={styles.itemIcon} />
            <span className={styles.itemLabel}>{label}</span>
          </Link>
        ))}
      </nav>

      <div className={styles.footer}>
        {sync.signedIn && (
          <button className={`${styles.syncRow} ${sync.busy ? styles.syncBusy : ''}`}
            onClick={syncNow} disabled={sync.busy} title="Синхронизировать">
            <RefreshCw size={13} className={`${styles.syncIcon} ${sync.busy ? styles.syncSpin : ''}`} />
            <span className={styles.syncText}>{status}</span>
          </button>
        )}
        {sync.error && <p className={styles.syncError}>{sync.error}</p>}

        <Link href="/settings"
          className={`${styles.item} ${isActive('/settings') ? styles.itemActive : ''}`}>
          {isActive('/settings') && (
            <motion.span className={styles.indicator} layoutId="sidebar-active"
              transition={{ type: 'spring', stiffness: 500, damping: 40 }} />
          )}
          <Settings size={18} className={styles.itemIcon} />
          <span className={styles.itemLabel}>Настройки</span>
        </Link>
      </div>
    </aside>
  );
}


