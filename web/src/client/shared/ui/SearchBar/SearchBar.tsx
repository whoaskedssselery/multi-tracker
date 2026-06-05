import { Search, X } from 'lucide-react';
import styles from './SearchBar.module.scss';

export interface SearchBarProps {
  value: string;
  onChange: (v: string) => void;
  placeholder?: string;
  className?: string;
}

export function SearchBar({ value, onChange, placeholder = 'Поиск', className }: SearchBarProps) {
  return (
    <div className={[styles.root, className].filter(Boolean).join(' ')}>
      <Search size={15} className={styles.icon} />
      <input
        className={styles.input}
        type="search"
        value={value}
        onChange={(e) => onChange(e.target.value)}
        placeholder={placeholder}
        autoComplete="off"
        autoCorrect="off"
        autoCapitalize="off"
        spellCheck={false}
      />
      {value && (
        <button className={styles.clear} onClick={() => onChange('')} aria-label="Очистить">
          <X size={13} />
        </button>
      )}
    </div>
  );
}

