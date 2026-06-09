'use client';

import { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { motion } from 'framer-motion';
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { z } from 'zod';
import { Sun, Moon, Monitor, RefreshCw, LogOut, Download, Trash2, Eye, EyeOff, Check, X } from 'lucide-react';
import toast from 'react-hot-toast';
import { useAppStore } from '@/shared/store';
import { createClient } from '@/shared/lib/supabase/client';
import { Modal, Button, Input } from '@/shared/ui';
import { useSync } from '@/features/sync';
import { formatSyncTime } from '@/shared/lib/utils/format';
import type { ThemeMode } from '@/shared/types';
import styles from './SettingsPage.module.scss';

const profileSchema = z.object({
  name:           z.string().min(1, 'Введите имя').max(80),
  heightCm:       z.coerce.number().int().min(100).max(250).optional().or(z.literal('')),
  targetWeightKg: z.coerce.number().min(30).max(300).optional().or(z.literal('')),
  units:          z.enum(['kg', 'lbs']),
});
type PF = z.infer<typeof profileSchema>;

const MODELS = ['llama-3.3-70b-versatile', 'deepseek-r1-distill-llama-70b', 'llama-3.1-8b-instant'];
const THEMES: { key: ThemeMode; label: string; Icon: typeof Sun }[] = [
  { key: 'light', label: 'Светлая',   Icon: Sun     },
  { key: 'dark',  label: 'Тёмная',    Icon: Moon    },
  { key: 'system',label: 'Системная', Icon: Monitor },
];

export function SettingsPage() {
  const navigate = useNavigate();
  const { syncNow } = useSync();

  const profile         = useAppStore(s => s.profile);
  const preferences     = useAppStore(s => s.preferences);
  const sync            = useAppStore(s => s.sync);
  const groqApiKey      = useAppStore(s => s.groqApiKey);
  const updateProfile   = useAppStore(s => s.updateProfile);
  const updatePrefs     = useAppStore(s => s.updatePreferences);
  const setGroqApiKey   = useAppStore(s => s.setGroqApiKey);
  const resetStore      = useAppStore(s => s.reset);

  const [profileOpen, setProfileOpen] = useState(false);
  const [keyOpen,     setKeyOpen]     = useState(false);
  const [keyDraft,    setKeyDraft]    = useState('');
  const [showKey,     setShowKey]     = useState(false);
  const [resetOpen,   setResetOpen]   = useState(false);
  const [appVersion,  setAppVersion]  = useState('');

  // Reload sync label every 30s
  const [, forceUpdate] = useState(0);
  useEffect(() => {
    const t = setInterval(() => forceUpdate(n => n + 1), 30_000);
    return () => clearInterval(t);
  }, []);

  // Read app version
  useEffect(() => {
    fetch('/manifest.json').then(r => r.json())
      .then(m => setAppVersion(m.version ?? '1.0.0'))
      .catch(() => setAppVersion('1.0.0'));
  }, []);

  const { register, handleSubmit, formState: { errors }, reset: resetForm } = useForm<PF>({
    resolver: zodResolver(profileSchema),
  });

  const openProfile = () => {
    resetForm({
      name: profile.name === 'User' ? '' : profile.name,
      heightCm: profile.heightCm ?? '',
      targetWeightKg: profile.targetWeightKg ?? '',
      units: profile.units,
    });
    setProfileOpen(true);
  };

  const saveProfile = (data: PF) => {
    updateProfile({
      name: data.name || 'User',
      heightCm: data.heightCm ? Number(data.heightCm) : null,
      targetWeightKg: data.targetWeightKg ? Number(data.targetWeightKg) : null,
      units: data.units,
    });
    setProfileOpen(false);
    toast.success('Профиль сохранён');
  };

  const setTheme = (mode: ThemeMode) => {
    updatePrefs({ themeMode: mode });
    const html = document.documentElement;
    if (mode === 'dark')  html.setAttribute('data-theme', 'dark');
    else if (mode === 'light') html.setAttribute('data-theme', 'light');
    else {
      const dark = window.matchMedia('(prefers-color-scheme: dark)').matches;
      html.setAttribute('data-theme', dark ? 'dark' : 'light');
    }
  };

  const saveKey = () => {
    const k = keyDraft.trim().replace(/^"|"$/g, '');
    setGroqApiKey(k || null);
    setKeyOpen(false); setKeyDraft('');
    toast.success(k ? 'API ключ сохранён' : 'API ключ удалён');
  };

  const signOut = async () => {
    try {
      await createClient().auth.signOut();
      resetStore();
      navigate('/auth');
    } catch { toast.error('Ошибка выхода'); }
  };

  const exportJson = () => {
    const snap = useAppStore.getState().exportSnapshot();
    const url  = URL.createObjectURL(new Blob([JSON.stringify(snap, null, 2)], { type: 'application/json' }));
    const a = Object.assign(document.createElement('a'), { href: url, download: `multi-tracker-${new Date().toISOString().slice(0, 10)}.json` });
    a.click(); URL.revokeObjectURL(url);
    toast.success('Экспортировано');
  };

  const syncStatus = sync.busy
    ? (sync.status ?? 'Синхронизация…')
    : sync.lastSynced
      ? `Синхронизировано ${formatSyncTime(sync.lastSynced)}`
      : 'Готово к синхронизации';

  return (
    <div className={styles.page}>
      <header className={styles.header}>
        <h1 className={styles.title}>Настройки</h1>
      </header>

      <div className={styles.scroll}>
        <Section label="ПРОФИЛЬ">
          <Row label="Имя"          value={profile.name === 'User' ? '—' : profile.name} onClick={openProfile} />
          <Div /><Row label="Рост"  value={profile.heightCm ? `${profile.heightCm} см` : '—'} onClick={openProfile} />
          <Div /><Row label="Вес"   value={profile.targetWeightKg ? `${profile.targetWeightKg} кг` : '—'} onClick={openProfile} />
        </Section>

        <Section label="ВНЕШНИЙ ВИД">
          <div className={styles.themes}>
            {THEMES.map(({ key, label, Icon }) => (
              <motion.button key={key} whileTap={{ scale: 0.97 }}
                className={`${styles.themeBtn} ${preferences.themeMode === key ? styles.themeBtnActive : ''}`}
                onClick={() => setTheme(key)}>
                <Icon size={16} />
                <span>{label}</span>
                {preferences.themeMode === key && <Check size={13} className={styles.themeCheck} />}
              </motion.button>
            ))}
          </div>
        </Section>

        <Section label="AI — GROQ">
          <div className={styles.keyRow}>
            <span className={styles.rowLabel}>Groq API Key</span>
            <div className={styles.keyVal}>
              {groqApiKey
                ? <span className={`${styles.keyMask} mono`}>{showKey ? groqApiKey : '●'.repeat(Math.min(groqApiKey.length, 32))}</span>
                : <span className={styles.keyNone}>Не настроен</span>}
              {groqApiKey && (
                <button className={styles.keyToggle} onClick={() => setShowKey(v => !v)}>
                  {showKey ? <EyeOff size={14} /> : <Eye size={14} />}
                </button>
              )}
              <button className={styles.keyEdit} onClick={() => { setKeyDraft(groqApiKey ?? ''); setKeyOpen(true); }}>
                {groqApiKey ? 'Изменить' : 'Добавить'}
              </button>
            </div>
          </div>
          <Div />
          <div className={styles.modelRow}>
            <span className={styles.rowLabel}>Модель</span>
            <select className={styles.select} value={preferences.aiModel}
              onChange={e => updatePrefs({ aiModel: e.target.value })}>
              {MODELS.map(m => <option key={m} value={m}>{m}</option>)}
            </select>
          </div>
        </Section>

        <Section label="СИНХРОНИЗАЦИЯ">
          {sync.signedIn ? (
            <>
              <Row label="Аккаунт" value={sync.email ?? '—'} />
              <Div />
              <div className={styles.syncRow}>
                <div>
                  <p className={styles.rowLabel}>Статус</p>
                  <p className={styles.syncStatus}>{syncStatus}</p>
                  {sync.error && <p className={styles.syncError}>{sync.error}</p>}
                </div>
                <Button variant="secondary" size="sm"
                  icon={<RefreshCw size={14} className={sync.busy ? styles.spin : ''} />}
                  loading={sync.busy} onClick={syncNow}>
                  Синхронизировать
                </Button>
              </div>
              <Div />
              <Row label="Выйти" value="" onClick={signOut} danger icon={<LogOut size={14} />} />
            </>
          ) : (
            <Row label="Войти" value="Для синхронизации с устройствами" onClick={() => navigate('/auth')} />
          )}
        </Section>

        <Section label="ДАННЫЕ">
          <Row label="Экспорт JSON" value="" onClick={exportJson} icon={<Download size={14} />} />
          <Div />
          <Row label="Сбросить данные" value="" onClick={() => setResetOpen(true)} icon={<Trash2 size={14} />} danger />
        </Section>

        <Section label="О ПРИЛОЖЕНИИ">
          <Row label="Версия" value={appVersion || '1.0.0'} />
          <Div /><Row label="Платформа" value="Web" />
        </Section>
      </div>

      {/* Profile modal */}
      <Modal open={profileOpen} onClose={() => setProfileOpen(false)} title="Профиль"
        footer={<><Button variant="secondary" onClick={() => setProfileOpen(false)}>Отмена</Button><Button variant="primary" onClick={handleSubmit(saveProfile)}>Сохранить</Button></>}>
        <div className={styles.form}>
          <Input label="Имя" placeholder="Как тебя зовут?" error={errors.name?.message} {...register('name')} />
          <div className={styles.row2}>
            <Input label="Рост" type="number" suffix="см" error={errors.heightCm?.message} {...register('heightCm')} />
            <Input label="Целевой вес" type="number" step="0.1" suffix="кг" error={errors.targetWeightKg?.message} {...register('targetWeightKg')} />
          </div>
          <div>
            <p className={styles.unitLabel}>Единицы</p>
            <div className={styles.unitBtns}>
              {(['kg', 'lbs'] as const).map(u => (
                <label key={u} className={styles.unitLabel}>
                  <input type="radio" value={u} {...register('units')} className="sr-only" />
                  <span className={`${styles.unitOpt} ${profile.units === u ? styles.unitActive : ''}`}>{u}</span>
                </label>
              ))}
            </div>
          </div>
        </div>
      </Modal>

      {/* Key modal */}
      <Modal open={keyOpen} onClose={() => setKeyOpen(false)} title="Groq API Key"
        footer={<><Button variant="secondary" onClick={() => setKeyOpen(false)}>Отмена</Button><Button variant="primary" onClick={saveKey}>Сохранить</Button></>}>
        <div className={styles.form}>
          <div className={styles.keyField}>
            <label className={styles.keyFieldLabel}>API Key</label>
            <div className={styles.keyInputWrap}>
              <input type={showKey ? 'text' : 'password'} className={styles.keyInput}
                placeholder="gsk_..." value={keyDraft} onChange={e => setKeyDraft(e.target.value)} autoComplete="off" />
              <button className={styles.keyInputToggle} onClick={() => setShowKey(v => !v)}>
                {showKey ? <EyeOff size={14} /> : <Eye size={14} />}
              </button>
            </div>
          </div>
          <p className={styles.keyHint}>Ключ хранится локально и отправляется только на api.groq.com</p>
        </div>
      </Modal>

      {/* Reset modal */}
      <Modal open={resetOpen} onClose={() => setResetOpen(false)} title="Сбросить данные?"
        footer={<><Button variant="secondary" onClick={() => setResetOpen(false)}>Отмена</Button><Button variant="danger" onClick={() => { resetStore(); setResetOpen(false); toast.success('Данные сброшены'); }}>Удалить всё</Button></>}>
        <p className={styles.resetText}>Удалит все локальные данные. Облачные данные останутся.</p>
      </Modal>
    </div>
  );
}

function Section({ label, children }: { label: string; children: React.ReactNode }) {
  return (
    <div className={styles.section}>
      <p className={styles.sectionLabel}>{label}</p>
      <div className={styles.card}>{children}</div>
    </div>
  );
}

function Row({ label, value, onClick, danger, icon }: { label: string; value: string; onClick?: () => void; danger?: boolean; icon?: React.ReactNode }) {
  return (
    <div className={`${styles.row} ${onClick ? styles.rowClickable : ''} ${danger ? styles.rowDanger : ''}`} onClick={onClick}>
      {icon && <span className={styles.rowIcon}>{icon}</span>}
      <span className={styles.rowLabel}>{label}</span>
      <span className={styles.rowValue}>{value}</span>
    </div>
  );
}

function Div() { return <hr className={styles.divider} />; }


