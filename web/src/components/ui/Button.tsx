import { forwardRef } from 'react';
import { motion } from 'framer-motion';
import { Loader2 } from 'lucide-react';
import s from './Button.module.scss';

type Variant = 'primary' | 'secondary' | 'ghost' | 'danger';
type Size    = 'sm' | 'md' | 'lg';

interface ButtonProps extends React.ButtonHTMLAttributes<HTMLButtonElement> {
  variant?: Variant;
  size?: Size;
  loading?: boolean;
  icon?: React.ReactNode;
  iconRight?: React.ReactNode;
}

export const Button = forwardRef<HTMLButtonElement, ButtonProps>(
  ({ variant = 'secondary', size = 'md', loading, icon, iconRight, children, className, disabled, ...rest }, ref) => (
    <motion.button
      ref={ref}
      className={[s.btn, s[variant], s[size], className].filter(Boolean).join(' ')}
      disabled={disabled || loading}
      whileTap={{ scale: 0.97 }}
      transition={{ duration: 0.1 }}
      {...(rest as React.ComponentProps<typeof motion.button>)}
    >
      {loading ? (
        <Loader2 size={size === 'sm' ? 14 : 16} className={s.spin} />
      ) : icon ? (
        <span className={s.icon}>{icon}</span>
      ) : null}
      {children && <span>{children}</span>}
      {iconRight && !loading && <span className={s.iconRight}>{iconRight}</span>}
    </motion.button>
  ),
);
Button.displayName = 'Button';
