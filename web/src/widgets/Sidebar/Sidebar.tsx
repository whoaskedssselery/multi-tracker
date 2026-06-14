import { Link, useLocation } from 'react-router-dom';
import { Home, Dumbbell, CheckSquare, Sparkles, Settings, RefreshCw } from 'lucide-react';
import { useAppStore } from '@/shared/store';
import { useSync } from '@/features/sync';
import { formatSyncTime } from '@/shared/lib/utils/format';
import styles from './Sidebar.module.scss';

const NAV = [
  { href: '/',      icon: Home,        label: 'Главная' },
  { href: '/train', icon: Dumbbell,    label: 'Тренировки' },
  { href: '/tasks', icon: CheckSquare, label: 'Задачи' },
  { href: '/ai',    icon: Sparkles,    label: 'ИИ' },
];

export function Sidebar() {
  const pathname = useLocation().pathname;
  const sync     = useAppStore(s => s.sync);
  const { syncNow } = useSync();

  const status = sync.busy
    ? (sync.status ?? 'Синхронизация…')
    : sync.lastSynced
      ? `Синхр. ${formatSyncTime(sync.lastSynced)}`
      : 'Готово';

  const isActive = (href: string) =>
    href === '/' ? pathname === '/' : pathname.startsWith(href);

  const item = (href: string, Icon: typeof Home, label: string) => (
    <Link key={href} to={href}
      className={`${styles.item} ${isActive(href) ? styles.itemActive : ''}`}>
      <Icon size={20} className={styles.itemIcon} strokeWidth={isActive(href) ? 2.4 : 2} />
      <span className={styles.itemLabel}>{label}</span>
    </Link>
  );

  return (
    <aside className={styles.sidebar}>
      <div className={styles.brand}>
        <img src="/icon.svg" className={styles.brandIcon} alt="" />
        <span className={styles.brandName}>Multi-tracker</span>
      </div>

      <nav className={styles.nav}>
        {NAV.map(n => item(n.href, n.icon, n.label))}
      </nav>

      <div className={styles.footer}>
        {sync.signedIn && (
          <button className={`${styles.syncRow} ${sync.busy ? styles.syncBusy : ''}`}
            onClick={syncNow} disabled={sync.busy} title="Синхронизировать">
            <RefreshCw size={14} className={`${styles.syncIcon} ${sync.busy ? styles.syncSpin : ''}`} />
            <span className={styles.syncText}>{status}</span>
          </button>
        )}
        {sync.error && <p className={styles.syncError}>{sync.error}</p>}
        {item('/settings', Settings, 'Настройки')}
      </div>
    </aside>
  );
}
