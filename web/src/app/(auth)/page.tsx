'use client';

import { useState } from 'react';
import { useRouter } from 'next/navigation';
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { z } from 'zod';
import { motion, AnimatePresence } from 'framer-motion';
import { Eye, EyeOff, LogIn, UserPlus, Loader2 } from 'lucide-react';
import toast from 'react-hot-toast';
import { createClient } from '@/lib/supabase/client';
import s from './page.module.scss';

const schema = z.object({
  email: z.string().min(1, 'Введите email').email('Некорректный email'),
  password: z.string().min(6, 'Минимум 6 символов'),
});
type FormData = z.infer<typeof schema>;

type Mode = 'signin' | 'signup';

export default function AuthPage() {
  const router = useRouter();
  const supabase = createClient();
  const [mode, setMode] = useState<Mode>('signin');
  const [showPass, setShowPass] = useState(false);
  const [loading, setLoading] = useState(false);

  const { register, handleSubmit, formState: { errors }, reset } = useForm<FormData>({
    resolver: zodResolver(schema),
  });

  const switchMode = (m: Mode) => {
    setMode(m);
    reset();
  };

  const onSubmit = async ({ email, password }: FormData) => {
    setLoading(true);
    try {
      if (mode === 'signin') {
        const { error } = await supabase.auth.signInWithPassword({ email, password });
        if (error) throw error;
        router.push('/');
        router.refresh();
      } else {
        const { data, error } = await supabase.auth.signUp({ email, password });
        if (error) throw error;
        if (!data.session) {
          toast.success('Подтвердите email, затем войдите.');
          setMode('signin');
        } else {
          router.push('/');
          router.refresh();
        }
      }
    } catch (err: unknown) {
      const msg = err instanceof Error ? err.message : 'Произошла ошибка';
      toast.error(msg);
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className={s.root}>
      {/* Background */}
      <div className={s.bg}>
        <div className={s.blob1} />
        <div className={s.blob2} />
      </div>

      <motion.div
        className={s.card}
        initial={{ opacity: 0, y: 24, scale: 0.97 }}
        animate={{ opacity: 1, y: 0, scale: 1 }}
        transition={{ duration: 0.4, ease: [0.22, 1, 0.36, 1] }}
      >
        {/* Logo */}
        <div className={s.logo}>
          <div className={s.logoIcon}>M</div>
          <span className={s.logoText}>Multi-tracker</span>
        </div>

        {/* Tab switcher */}
        <div className={s.tabs}>
          {(['signin', 'signup'] as Mode[]).map((m) => (
            <button
              key={m}
              className={`${s.tab} ${mode === m ? s.tabActive : ''}`}
              onClick={() => switchMode(m)}
              type="button"
            >
              {m === 'signin' ? 'Войти' : 'Регистрация'}
            </button>
          ))}
        </div>

        <AnimatePresence mode="wait">
          <motion.form
            key={mode}
            className={s.form}
            onSubmit={handleSubmit(onSubmit)}
            initial={{ opacity: 0, x: mode === 'signin' ? -16 : 16 }}
            animate={{ opacity: 1, x: 0 }}
            exit={{ opacity: 0, x: mode === 'signin' ? 16 : -16 }}
            transition={{ duration: 0.2, ease: 'easeInOut' }}
          >
            {/* Email */}
            <div className={s.field}>
              <label className={s.label} htmlFor="email">Email</label>
              <input
                id="email"
                type="email"
                className={`${s.input} ${errors.email ? s.inputError : ''}`}
                placeholder="you@example.com"
                autoComplete="email"
                {...register('email')}
              />
              {errors.email && (
                <span className={s.error}>{errors.email.message}</span>
              )}
            </div>

            {/* Password */}
            <div className={s.field}>
              <label className={s.label} htmlFor="password">Пароль</label>
              <div className={s.passWrap}>
                <input
                  id="password"
                  type={showPass ? 'text' : 'password'}
                  className={`${s.input} ${errors.password ? s.inputError : ''}`}
                  placeholder="••••••••"
                  autoComplete={mode === 'signin' ? 'current-password' : 'new-password'}
                  {...register('password')}
                />
                <button
                  type="button"
                  className={s.passToggle}
                  onClick={() => setShowPass(v => !v)}
                  aria-label={showPass ? 'Скрыть пароль' : 'Показать пароль'}
                >
                  {showPass ? <EyeOff size={16} /> : <Eye size={16} />}
                </button>
              </div>
              {errors.password && (
                <span className={s.error}>{errors.password.message}</span>
              )}
            </div>

            {/* Submit */}
            <motion.button
              className={s.submit}
              type="submit"
              disabled={loading}
              whileTap={{ scale: 0.98 }}
            >
              {loading
                ? <Loader2 size={18} className={s.spin} />
                : mode === 'signin'
                  ? <><LogIn size={16} /> Войти</>
                  : <><UserPlus size={16} /> Создать аккаунт</>
              }
            </motion.button>
          </motion.form>
        </AnimatePresence>

        <p className={s.hint}>
          Данные синхронизируются с iOS и Windows приложением
        </p>
      </motion.div>
    </div>
  );
}
