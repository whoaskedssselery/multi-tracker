import { forwardRef } from 'react';
import styles from './Input.module.scss';

export interface InputProps extends React.InputHTMLAttributes<HTMLInputElement> {
  label?: string;
  error?: string;
  suffix?: string;
}

export const Input = forwardRef<HTMLInputElement, InputProps>(
  ({ label, error, suffix, className, id, ...rest }, ref) => {
    const fieldId = id ?? label?.toLowerCase().replace(/\s+/g, '-');
    return (
      <div className={styles.field}>
        {label && <label className={styles.label} htmlFor={fieldId}>{label}</label>}
        <div className={styles.wrap}>
          <input
            ref={ref}
            id={fieldId}
            className={[styles.input, error && styles.error, suffix && styles.hasSuffix, className]
              .filter(Boolean).join(' ')}
            {...rest}
          />
          {suffix && <span className={styles.suffix}>{suffix}</span>}
        </div>
        {error && <span className={styles.errorMsg}>{error}</span>}
      </div>
    );
  },
);
Input.displayName = 'Input';

export interface TextareaProps extends React.TextareaHTMLAttributes<HTMLTextAreaElement> {
  label?: string;
  error?: string;
}

export const Textarea = forwardRef<HTMLTextAreaElement, TextareaProps>(
  ({ label, error, className, id, ...rest }, ref) => {
    const fieldId = id ?? label?.toLowerCase().replace(/\s+/g, '-');
    return (
      <div className={styles.field}>
        {label && <label className={styles.label} htmlFor={fieldId}>{label}</label>}
        <textarea
          ref={ref}
          id={fieldId}
          className={[styles.textarea, error && styles.error, className].filter(Boolean).join(' ')}
          {...rest}
        />
        {error && <span className={styles.errorMsg}>{error}</span>}
      </div>
    );
  },
);
Textarea.displayName = 'Textarea';

