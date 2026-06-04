import { forwardRef } from 'react';
import s from './Input.module.scss';

interface InputProps extends React.InputHTMLAttributes<HTMLInputElement> {
  label?: string;
  error?: string;
  suffix?: string;
}

export const Input = forwardRef<HTMLInputElement, InputProps>(
  ({ label, error, suffix, className, id, ...rest }, ref) => {
    const fieldId = id ?? label?.toLowerCase().replace(/\s+/g, '-');
    return (
      <div className={s.field}>
        {label && <label className={s.label} htmlFor={fieldId}>{label}</label>}
        <div className={s.wrap}>
          <input
            ref={ref}
            id={fieldId}
            className={[s.input, error && s.inputError, suffix && s.inputSuffix, className]
              .filter(Boolean).join(' ')}
            {...rest}
          />
          {suffix && <span className={s.suffixLabel}>{suffix}</span>}
        </div>
        {error && <span className={s.error}>{error}</span>}
      </div>
    );
  },
);
Input.displayName = 'Input';

interface TextareaProps extends React.TextareaHTMLAttributes<HTMLTextAreaElement> {
  label?: string;
  error?: string;
}

export const Textarea = forwardRef<HTMLTextAreaElement, TextareaProps>(
  ({ label, error, className, id, ...rest }, ref) => {
    const fieldId = id ?? label?.toLowerCase().replace(/\s+/g, '-');
    return (
      <div className={s.field}>
        {label && <label className={s.label} htmlFor={fieldId}>{label}</label>}
        <textarea
          ref={ref}
          id={fieldId}
          className={[s.textarea, error && s.inputError, className].filter(Boolean).join(' ')}
          {...rest}
        />
        {error && <span className={s.error}>{error}</span>}
      </div>
    );
  },
);
Textarea.displayName = 'Textarea';
