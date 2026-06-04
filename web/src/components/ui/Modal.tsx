'use client';

import { useEffect } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { X } from 'lucide-react';
import s from './Modal.module.scss';

interface ModalProps {
  open: boolean;
  onClose: () => void;
  title?: string;
  children: React.ReactNode;
  maxWidth?: number;
  footer?: React.ReactNode;
}

export function Modal({ open, onClose, title, children, maxWidth = 480, footer }: ModalProps) {
  // Dismiss on Escape
  useEffect(() => {
    if (!open) return;
    const handler = (e: KeyboardEvent) => { if (e.key === 'Escape') onClose(); };
    document.addEventListener('keydown', handler);
    return () => document.removeEventListener('keydown', handler);
  }, [open, onClose]);

  // Lock body scroll
  useEffect(() => {
    if (open) document.body.style.overflow = 'hidden';
    else document.body.style.overflow = '';
    return () => { document.body.style.overflow = ''; };
  }, [open]);

  return (
    <AnimatePresence>
      {open && (
        <>
          {/* Backdrop */}
          <motion.div
            className={s.backdrop}
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            transition={{ duration: 0.18 }}
            onClick={onClose}
          />

          {/* Dialog */}
          <div className={s.wrapper} role="dialog" aria-modal>
            <motion.div
              className={s.dialog}
              style={{ maxWidth }}
              initial={{ opacity: 0, scale: 0.95, y: 8 }}
              animate={{ opacity: 1, scale: 1,    y: 0 }}
              exit={{ opacity: 0, scale: 0.95, y: 8 }}
              transition={{ type: 'spring', stiffness: 500, damping: 40 }}
            >
              {/* Header */}
              {title && (
                <div className={s.header}>
                  <h2 className={s.title}>{title}</h2>
                  <button className={s.close} onClick={onClose} aria-label="Закрыть">
                    <X size={18} />
                  </button>
                </div>
              )}
              {!title && (
                <button className={s.closeAbs} onClick={onClose} aria-label="Закрыть">
                  <X size={18} />
                </button>
              )}

              {/* Body */}
              <div className={s.body}>{children}</div>

              {/* Footer */}
              {footer && <div className={s.footer}>{footer}</div>}
            </motion.div>
          </div>
        </>
      )}
    </AnimatePresence>
  );
}
