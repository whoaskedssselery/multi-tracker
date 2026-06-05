'use client';

import { useState } from 'react';
import { useRouter } from 'next/navigation';
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { z } from 'zod';
import { motion, AnimatePresence } from 'framer-motion';
import { Eye, EyeOff, LogIn, UserPlus, Loader2 } from 'lucide-react';
import toast from 'react-hot-toast';
import { createClient } from '@frontend/shared/lib/supabase/client';
import styles from './AuthForm.module.scss';

const schema = z.object({
  email:    z.string().min(1, 'Введите email').email('Некорректный email'),
  password: z.string().min(6, 'Минимум 6 символов'),
});
type FormData = z.infer<typeof schema>;
type Mode = 'signin' | 'signup';

export function AuthForm() {
  const router = useRouter();
  const supabase = createClient();
  const [mode, setMode]       = useState<Mode>('signin');
  const [showPass, setShowPass] = useState(false);
  const [loading, setLoading]   = useState(false);

  const { register, handleSubmit, formState: { errors }, reset } = useForm<FormData>({
    resolver: zodResolver(schema),
  });

  const switchMode = (m: Mode) => { setMode(m); reset(); };

  const onSubmit = async ({ email, password }: FormData) => {
    setLoading(true);
    try {
      if (mode === 'signin') {
        const { error } = await supabase.auth.signInWithPassword({ email, password });
        if (error) throw error;
      } else {
        const { data, error } = await supabase.auth.signUp({ email, password });
        if (error) throw error;
        if (!data.session) {
          toast.success('Подтвердите email, затем войдите.');
          switchMode('signin');
          return;
        }
      }
      router.push('/');
      router.refresh();
    } catch (err: unknown) {
      toast.error(err instanceof Error ? err.message : 'Произошла ошибка');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className={styles.root}>
      <div className={styles.bg}>
        <div className={styles.blob1} />
        <div className={styles.blob2} />
      </div>

      <motion.div className={styles.card}
        initial={{ opacity: 0, y: 24, scale: 0.97 }}
        animate={{ opacity: 1, y: 0,  scale: 1 }}
        transition={{ duration: 0.4, ease: [0.22, 1, 0.36, 1] }}>

        <div className={styles.logo}>
          <div className={styles.logoIcon}>M</div>
          <span className={styles.logoText}>Multi-tracker</span>
        </div>

        <div className={styles.tabs}>
          {(['signin', 'signup'] as Mode[]).map(m => (
            <button key={m} type="button"
              className={`${styles.tab} ${mode === m ? styles.tabActive : ''}`}
              onClick={() => switchMode(m)}>
              {m === 'signin' ? 'Войти' : 'Регистрация'}
            </button>
          ))}
        </div>

        <AnimatePresence mode="wait">
          <motion.form key={mode} className={styles.form} onSubmit={handleSubmit(onSubmit)}
            initial={{ opacity: 0, x: mode === 'signin' ? -16 : 16 }}
            animate={{ opacity: 1, x: 0 }}
            exit={{ opacity: 0 }}
            transition={{ duration: 0.18 }}>

            <div className={styles.field}>
              <label className={styles.label} htmlFor="auth-email">Email</label>
              <input id="auth-email" type="email" autoComplete="email"
                className={`${styles.input} ${errors.email ? styles.inputError : ''}`}
                placeholder="you@example.com"
                {...register('email')} />
              {errors.email && <span className={styles.errMsg}>{errors.email.message}</span>}
            </div>

            <div className={styles.field}>
              <label className={styles.label} htmlFor="auth-pass">Пароль</label>
              <div className={styles.passWrap}>
                <input id="auth-pass"
                  type={showPass ? 'text' : 'password'}
                  autoComplete={mode === 'signin' ? 'current-password' : 'new-password'}
                  className={`${styles.input} ${errors.password ? styles.inputError : ''}`}
                  placeholder="••••••••"
                  {...register('password')} />
                <button type="button" className={styles.passToggle}
                  onClick={() => setShowPass(v => !v)}
                  aria-label={showPass ? 'Скрыть' : 'Показать'}>
                  {showPass ? <EyeOff size={16} /> : <Eye size={16} />}
                </button>
              </div>
              {errors.password && <span className={styles.errMsg}>{errors.password.message}</span>}
            </div>

            <motion.button className={styles.submit} type="submit"
              disabled={loading} whileTap={{ scale: 0.98 }}>
              {loading
                ? <Loader2 size={18} className={styles.spin} />
                : mode === 'signin'
                  ? <><LogIn size={16} /> Войти</>
                  : <><UserPlus size={16} /> Создать аккаунт</>
              }
            </motion.button>
          </motion.form>
        </AnimatePresence>

        <p className={styles.hint}>Данные синхронизируются с iOS и Windows приложением</p>
      </motion.div>
    </div>
  );
}


