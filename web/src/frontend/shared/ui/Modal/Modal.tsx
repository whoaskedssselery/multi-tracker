'use client';

import { useEffect, useCallback } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { X } from 'lucide-react';
import styles from './Modal.module.scss';

export interface ModalProps {
  open: boolean;
  onClose: () => void;
  title?: string;
  children: React.ReactNode;
  maxWidth?: number;
  footer?: React.ReactNode;
}

export function Modal({ open, onClose, title, children, maxWidth = 480, footer }: ModalProps) {
  const close = useCallback(() => onClose(), [onClose]);

  useEffect(() => {
    if (!open) return;
    const onKey = (e: KeyboardEvent) => { if (e.key === 'Escape') close(); };
    document.addEventListener('keydown', onKey);
    return () => document.removeEventListener('keydown', onKey);
  }, [open, close]);

  useEffect(() => {
    if (open) document.body.style.overflow = 'hidden';
    else document.body.style.overflow = '';
    return () => { document.body.style.overflow = ''; };
  }, [open]);

  return (
    <AnimatePresence>
      {open && (
        <>
          <motion.div
            className={styles.backdrop}
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            transition={{ duration: 0.18 }}
            onClick={close}
          />
          <div className={styles.wrapper} role="dialog" aria-modal>
            <motion.div
              className={styles.dialog}
              style={{ maxWidth }}
              initial={{ opacity: 0, scale: 0.96, y: 12 }}
              animate={{ opacity: 1, scale: 1,    y: 0 }}
              exit={{ opacity: 0, scale: 0.96, y: 12 }}
              transition={{ type: 'spring', stiffness: 480, damping: 38 }}
            >
              {title ? (
                <div className={styles.header}>
                  <h2 className={styles.title}>{title}</h2>
                  <button className={styles.closeBtn} onClick={close} aria-label="Закрыть">
                    <X size={18} />
                  </button>
                </div>
              ) : (
                <button className={styles.closeBtnAbs} onClick={close} aria-label="Закрыть">
                  <X size={18} />
                </button>
              )}
              <div className={styles.body}>{children}</div>
              {footer && <div className={styles.footer}>{footer}</div>}
            </motion.div>
          </div>
        </>
      )}
    </AnimatePresence>
  );
}

