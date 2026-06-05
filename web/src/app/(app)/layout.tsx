import { AppShell } from '@frontend/widgets/AppShell';
export default function AppLayout({ children }: { children: React.ReactNode }) {
  return <AppShell>{children}</AppShell>;
}


