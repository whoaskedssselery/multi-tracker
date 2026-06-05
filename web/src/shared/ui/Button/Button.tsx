import { forwardRef } from 'react';
import { motion } from 'framer-motion';
import { Loader2 } from 'lucide-react';
import styles from './Button.module.scss';

export type ButtonVariant = 'primary' | 'secondary' | 'ghost' | 'danger';
export type ButtonSize    = 'sm' | 'md' | 'lg';

export interface ButtonProps extends React.ButtonHTMLAttributes<HTMLButtonElement> {
  variant?: ButtonVariant;
  size?: ButtonSize;
  loading?: boolean;
  icon?: React.ReactNode;
  iconRight?: React.ReactNode;
  fullWidth?: boolean;
}

export const Button = forwardRef<HTMLButtonElement, ButtonProps>(
  ({ variant = 'secondary', size = 'md', loading, icon, iconRight,
     fullWidth, children, className, disabled, ...rest }, ref) => (
    <motion.button
      ref={ref}
      className={[
        styles.btn,
        styles[variant],
        styles[size],
        fullWidth && styles.full,
        className,
      ].filter(Boolean).join(' ')}
      disabled={disabled || loading}
      whileTap={{ scale: 0.97 }}
      transition={{ duration: 0.1 }}
      {...(rest as React.ComponentProps<typeof motion.button>)}
    >
      {loading
        ? <Loader2 size={size === 'sm' ? 14 : 16} className={styles.spin} />
        : icon && <span className={styles.icon}>{icon}</span>}
      {children && <span>{children}</span>}
      {!loading && iconRight && <span className={styles.iconRight}>{iconRight}</span>}
    </motion.button>
  ),
);
Button.displayName = 'Button';
