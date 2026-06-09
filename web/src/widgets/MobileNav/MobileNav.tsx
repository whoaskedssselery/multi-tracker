'use client';

import { Link } from 'react-router-dom';
import { useLocation } from 'react-router-dom';
import { motion } from 'framer-motion';
import { Home, Dumbbell, CheckSquare, Sparkles, Settings } from 'lucide-react';
import styles from './MobileNav.module.scss';

const NAV = [
  { href: '/',         icon: Home,        label: 'Главная' },
  { href: '/train',    icon: Dumbbell,    label: 'Трени' },
  { href: '/tasks',    icon: CheckSquare, label: 'Задачи' },
  { href: '/ai',       icon: Sparkles,    label: 'ИИ' },
  { href: '/settings', icon: Settings,    label: 'Настройки' },
];

export function MobileNav() {
  const pathname = useLocation().pathname;

  return (
    <nav className={styles.nav} aria-label="Навигация">
      {NAV.map(({ href, icon: Icon, label }) => {
        const active = href === '/' ? pathname === '/' : pathname.startsWith(href);
        return (
          <Link key={href} to={href} className={`${styles.item} ${active ? styles.itemActive : ''}`}>
            <span className={styles.iconWrap}>
              <Icon size={24} strokeWidth={active ? 2.2 : 1.8} />
              {active && (
                <motion.span className={styles.dot} layoutId="mob-dot"
                  transition={{ type: 'spring', stiffness: 600, damping: 40 }} />
              )}
            </span>
            <span className={styles.label}>{label}</span>
          </Link>
        );
      })}
    </nav>
  );
}

