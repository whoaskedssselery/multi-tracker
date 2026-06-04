'use client';

import Link from 'next/link';
import { usePathname } from 'next/navigation';
import { motion } from 'framer-motion';
import { Home, Dumbbell, CheckSquare, Sparkles, Settings } from 'lucide-react';
import s from './MobileNav.module.scss';

const NAV = [
  { href: '/',         icon: Home,        label: 'Главная' },
  { href: '/train',    icon: Dumbbell,    label: 'Трени' },
  { href: '/tasks',    icon: CheckSquare, label: 'Задачи' },
  { href: '/ai',       icon: Sparkles,    label: 'ИИ' },
  { href: '/settings', icon: Settings,    label: 'Настройки' },
];

export function MobileNav() {
  const pathname = usePathname();

  return (
    <nav className={s.nav}>
      {NAV.map(({ href, icon: Icon, label }) => {
        const active = href === '/' ? pathname === '/' : pathname.startsWith(href);
        return (
          <Link key={href} href={href} className={`${s.item} ${active ? s.itemActive : ''}`}>
            <span className={s.iconWrap}>
              <Icon size={22} />
              {active && (
                <motion.span
                  className={s.dot}
                  layoutId="mobile-nav-dot"
                  transition={{ type: 'spring', stiffness: 600, damping: 40 }}
                />
              )}
            </span>
            <span className={s.label}>{label}</span>
          </Link>
        );
      })}
    </nav>
  );
}
