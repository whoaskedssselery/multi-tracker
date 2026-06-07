'use client';

import { usePathname } from 'next/navigation';
import { AppShell } from '@/widgets/AppShell';

/// Wraps every route. Auth screens render bare (no sidebar/nav and no sync);
/// all other routes get the full app shell. This replaces Next.js route groups
/// — keeping a single, flat `app/` tree with no `(group)` folders.
export function RouteShell({ children }: { children: React.ReactNode }) {
  const pathname = usePathname();
  const isAuth = pathname?.startsWith('/auth');

  if (isAuth) return <>{children}</>;
  return <AppShell>{children}</AppShell>;
}
