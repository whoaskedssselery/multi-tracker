'use client';

import { useState } from 'react';
import { useRouter } from 'next/navigation';
import { motion } from 'framer-motion';
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { z } from 'zod';
import {
  User, Sun, Moon, Monitor, Key, RefreshCw, LogOut,
  Download, Upload, Trash2, Eye, EyeOff, Check, X,
} from 'lucide-react';
import toast from 'react-hot-toast';
import { useAppStore } from '@/store/app-store';
import { createClient } from '@/lib/supabase/client';
import { Modal } from '@/components/ui/Modal';
import { Button } from '@/components/ui/Button';
import { Input } from '@/components/ui/Input';
import { formatSyncTime } from '@/lib/utils/format';
import type { ThemeMode } from '@/types';
import { useSync } from '@/lib/hooks/useSync';
import s from './page.module.scss';

const profileSchema = z.object({
  name:           z.string().min(1, 'Введите имя').max(80),
  heightCm:       z.coerce.number().int().min(100).max(250).optional().or(z.literal('')),
  targetWeightKg: z.coerce.number().min(30).max(300).optional().or(z.literal('')),
  units:          z.enum(['kg', 'lbs']),
});
type ProfileForm = z.infer<typeof profileSchema>;

export default function SettingsPage() {
  const router = useRouter();
  const { syncNow } = useSync();
  const profile     = useAppStore(s => s.profile);
  const preferences = useAppStore(s => s.preferences);
  const sync        = useAppStore(s => s.sync);
  const groqApiKey  = useAppStore(s => s.groqApiKey);
  const updateProfile     = useAppStore(s => s.updateProfile);
  const updatePreferences = useAppStore(s => s.updatePreferences);
  const setGroqApiKey     = useAppStore(s => s.setGroqApiKey);
  const reset             = useAppStore(s => s.reset);

  const [profileOpen, setProfileOpen] = useState(false);
  const [keyOpen, setKeyOpen]         = useState(false);
  const [keyDraft, setKeyDraft]       = useState('');
  const [showKey, setShowKey]         = useState(false);
  const [resetOpen, setResetOpen]     = useState(false);
  const [signingOut, setSigningOut]   = useState(false);

  const { register, handleSubmit, formState: { errors }, reset: resetForm } = useForm<ProfileForm>({
    resolver: zodResolver(profileSchema),
    defaultValues: {
      name: profile.name === 'User' ? '' : profile.name,
      heightCm: profile.heightCm ?? '',
      targetWeightKg: profile.targetWeightKg ?? '',
      units: profile.units,
    },
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

  const saveProfile = (data: ProfileForm) => {
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
    updatePreferences({ themeMode: mode });
    const html = document.documentElement;
    if (mode === 'dark') html.setAttribute('data-theme', 'dark');
    else if (mode === 'light') html.setAttribute('data-theme', 'light');
    else {
      const dark = window.matchMedia('(prefers-color-scheme: dark)').matches;
      html.setAttribute('data-theme', dark ? 'dark' : 'light');
    }
  };

  const saveKey = () => {
    const k = keyDraft.trim().replace(/^"|"$/g, '');
    setGroqApiKey(k || null);
    setKeyOpen(false);
    setKeyDraft('');
    toast.success(k ? 'API ключ сохранён' : 'API ключ удалён');
  };

  const signOut = async () => {
    setSigningOut(true);
    try {
      const supabase = createClient();
      await supabase.auth.signOut();
      reset();
      router.push('/auth');
    } catch {
      toast.error('Ошибка выхода');
    } finally {
      setSigningOut(false);
    }
  };

  const confirmReset = async () => {
    reset();
    setResetOpen(false);
    toast.success('Данные сброшены');
  };

  const exportJson = () => {
    const snap = useAppStore.getState().exportSnapshot();
    const blob = new Blob([JSON.stringify(snap, null, 2)], { type: 'application/json' });
    const url  = URL.createObjectURL(blob);
    const a    = document.createElement('a');
    a.href = url;
    a.download = `multi-tracker-${new Date().toISOString().slice(0, 10)}.json`;
    a.click();
    URL.revokeObjectURL(url);
    toast.success('Экспортировано');
  };

  const MODELS = [
    'llama-3.3-70b-versatile',
    'deepseek-r1-distill-llama-70b',
    'llama-3.1-8b-instant',
  ];

  const THEMES: { key: ThemeMode; label: string; icon: typeof Sun }[] = [
    { key: 'light', label: 'Светлая',  icon: Sun },
    { key: 'dark',  label: 'Тёмная',   icon: Moon },
    { key: 'system',label: 'Системная',icon: Monitor },
  ];

  return (
    <div className={s.page}>
      <div className={s.header}>
        <h1 className={s.title}>Настройки</h1>
      </div>

      <div className={s.content}>
        {/* Profile */}
        <Section label="ПРОФИЛЬ">
          <Row label="Имя" value={profile.name === 'User' ? '—' : profile.name} onClick={openProfile} />
          <Divider />
          <Row label="Рост" value={profile.heightCm ? `${profile.heightCm} см` : '—'} onClick={openProfile} />
          <Divider />
          <Row label="Целевой вес" value={profile.targetWeightKg ? `${profile.targetWeightKg} кг` : '—'} onClick={openProfile} />
        </Section>

        {/* Appearance */}
        <Section label="ВНЕШНИЙ ВИД">
          <div className={s.themes}>
            {THEMES.map(({ key, label, icon: Icon }) => (
              <motion.button
                key={key}
                className={`${s.themeBtn} ${preferences.themeMode === key ? s.themeBtnActive : ''}`}
                onClick={() => setTheme(key)}
                whileTap={{ scale: 0.97 }}
              >
                <Icon size={18} />
                <span>{label}</span>
                {preferences.themeMode === key && <Check size={14} className={s.themeCheck} />}
              </motion.button>
            ))}
          </div>
        </Section>

        {/* AI */}
        <Section label="AI — GROQ">
          <div className={s.keyRow}>
            <span className={s.keyLabel}>Groq API Key</span>
            <div className={s.keyVal}>
              {groqApiKey ? (
                <span className={`${s.keyMask} mono`}>
                  {showKey ? groqApiKey : '●'.repeat(Math.min(groqApiKey.length, 32))}
                </span>
              ) : <span className={s.keyNone}>Не настроен</span>}
              {groqApiKey && (
                <button className={s.keyToggle} onClick={() => setShowKey(v => !v)}>
                  {showKey ? <EyeOff size={14} /> : <Eye size={14} />}
                </button>
              )}
              <button
                className={s.keyEdit}
                onClick={() => { setKeyDraft(groqApiKey ?? ''); setKeyOpen(true); }}
              >
                {groqApiKey ? 'Изменить' : 'Добавить'}
              </button>
            </div>
          </div>
          <Divider />
          <div className={s.modelsRow}>
            <span className={s.rowLabel}>Модель</span>
            <select
              className={s.select}
              value={preferences.aiModel}
              onChange={e => updatePreferences({ aiModel: e.target.value })}
            >
              {MODELS.map(m => <option key={m} value={m}>{m}</option>)}
            </select>
          </div>
        </Section>

        {/* Sync */}
        <Section label="СИНХРОНИЗАЦИЯ">
          {sync.signedIn ? (
            <>
              <Row
                label="Аккаунт"
                value={sync.email ?? '—'}
              />
              <Divider />
              <div className={s.syncStatusRow}>
                <div>
                  <p className={s.rowLabel}>Статус</p>
                  <p className={s.syncStatus}>
                    {sync.busy
                      ? (sync.status ?? 'Синхронизация…')
                      : sync.lastSynced
                        ? `Синхронизировано ${formatSyncTime(sync.lastSynced)}`
                        : 'Готово к синхронизации'}
                  </p>
                  {sync.error && <p className={s.syncError}>{sync.error}</p>}
                </div>
                <Button
                  variant="secondary" size="sm"
                  icon={<RefreshCw size={14} className={sync.busy ? s.syncSpin : ''} />}
                  loading={sync.busy}
                  onClick={syncNow}
                >
                  Синхронизировать
                </Button>
              </div>
              <Divider />
              <Row
                label="Выйти"
                value={sync.email ?? ''}
                onClick={signOut}
                danger
                icon={<LogOut size={14} />}
              />
            </>
          ) : (
            <Row label="Войти" value="Для синхронизации с устройствами" onClick={() => router.push('/auth')} />
          )}
        </Section>

        {/* Data */}
        <Section label="ДАННЫЕ">
          <Row label="Экспорт JSON" value="" onClick={exportJson} icon={<Download size={14} />} />
          <Divider />
          <Row label="Сбросить данные" value="" onClick={() => setResetOpen(true)} icon={<Trash2 size={14} />} danger />
        </Section>
      </div>

      {/* Profile modal */}
      <Modal open={profileOpen} onClose={() => setProfileOpen(false)} title="Профиль"
        footer={<><Button variant="secondary" onClick={() => setProfileOpen(false)}>Отмена</Button><Button variant="primary" onClick={handleSubmit(saveProfile)}>Сохранить</Button></>}>
        <div className={s.form}>
          <Input label="Имя" placeholder="Как тебя зовут?" error={errors.name?.message} {...register('name')} />
          <div className={s.row2}>
            <Input label="Рост" type="number" suffix="см" error={errors.heightCm?.message} {...register('heightCm')} />
            <Input label="Целевой вес" type="number" step="0.1" suffix="кг" error={errors.targetWeightKg?.message} {...register('targetWeightKg')} />
          </div>
          <div>
            <p className={s.formLabel}>Единицы</p>
            <div className={s.unitBtns}>
              {(['kg', 'lbs'] as const).map(u => (
                <label key={u} className={s.unitLabel}>
                  <input type="radio" value={u} {...register('units')} className="sr-only" />
                  <span className={`${s.unitOpt} ${profile.units === u ? s.unitOptActive : ''}`}>{u}</span>
                </label>
              ))}
            </div>
          </div>
        </div>
      </Modal>

      {/* Key modal */}
      <Modal open={keyOpen} onClose={() => setKeyOpen(false)} title="Groq API Key"
        footer={<><Button variant="secondary" onClick={() => setKeyOpen(false)}>Отмена</Button><Button variant="primary" onClick={saveKey}>Сохранить</Button></>}>
        <div className={s.form}>
          <div className={s.keyField}>
            <label className={s.keyFieldLabel}>API Key</label>
            <div className={s.keyInputWrap}>
              <input
                type={showKey ? 'text' : 'password'}
                className={s.keyInput}
                placeholder="gsk_..."
                value={keyDraft}
                onChange={e => setKeyDraft(e.target.value)}
                autoComplete="off"
              />
              <button className={s.keyInputToggle} onClick={() => setShowKey(v => !v)}>
                {showKey ? <EyeOff size={14} /> : <Eye size={14} />}
              </button>
            </div>
            {keyDraft && <Button variant="ghost" size="sm" icon={<X size={12} />} onClick={() => setKeyDraft('')}>Очистить</Button>}
          </div>
          <p className={s.keyHint}>Ключ хранится локально и отправляется только на api.groq.com</p>
        </div>
      </Modal>

      {/* Reset confirm */}
      <Modal open={resetOpen} onClose={() => setResetOpen(false)} title="Сбросить данные?"
        footer={<><Button variant="secondary" onClick={() => setResetOpen(false)}>Отмена</Button><Button variant="danger" onClick={confirmReset}>Удалить всё</Button></>}>
        <p className={s.resetText}>Это действие удалит все локальные данные. Данные в облаке останутся — для восстановления выполни синхронизацию после входа.</p>
      </Modal>
    </div>
  );
}

function Section({ label, children }: { label: string; children: React.ReactNode }) {
  return (
    <div className={s.section}>
      <p className={s.sectionLabel}>{label}</p>
      <div className={s.card}>{children}</div>
    </div>
  );
}

function Row({ label, value, onClick, danger, icon }: {
  label: string; value: string; onClick?: () => void; danger?: boolean; icon?: React.ReactNode;
}) {
  return (
    <div className={`${s.row} ${onClick ? s.rowClickable : ''} ${danger ? s.rowDanger : ''}`} onClick={onClick}>
      {icon && <span className={s.rowIcon}>{icon}</span>}
      <span className={s.rowLabel}>{label}</span>
      <span className={s.rowValue}>{value}</span>
    </div>
  );
}

function Divider() {
  return <hr className={s.divider} />;
}
