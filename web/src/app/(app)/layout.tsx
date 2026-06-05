import { AppShell } from '@client/widgets/AppShell';
export default function AppLayout({ children }: { children: React.ReactNode }) {
  return <AppShell>{children}</AppShell>;
}

