'use client';

import { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { z } from 'zod';
import { motion, AnimatePresence } from 'framer-motion';
import { Eye, EyeOff, LogIn, UserPlus, Loader2, ArrowLeft, MailCheck } from 'lucide-react';
import toast from 'react-hot-toast';
import { createClient } from '@/shared/lib/supabase/client';
import styles from './AuthForm.module.scss';

const schema = z.object({
  email:    z.string().min(1, 'Введите email').email('Некорректный email'),
  password: z.string().min(6, 'Минимум 6 символов'),
});
type FormData = z.infer<typeof schema>;
type Mode = 'signin' | 'signup';
type Step = 'form' | 'otp';

// Maps Supabase auth errors to clear Russian text.
function authErrorMessage(err: unknown): string {
  const msg = err instanceof Error ? err.message : '';
  if (/invalid login credentials/i.test(msg))
    return 'Неверная почта или пароль. Если аккаунта ещё нет — зарегистрируйтесь.';
  if (/expired|invalid.*(otp|token)|otp.*expired|invalid token/i.test(msg))
    return 'Неверный или просроченный код. Запросите новый.';
  if (/email not confirmed/i.test(msg))
    return 'Почта не подтверждена — введите код из письма.';
  if (/user already registered|already registered/i.test(msg))
    return 'Аккаунт с такой почтой уже есть — войдите.';
  if (/(rate limit|too many)/i.test(msg))
    return 'Слишком много попыток. Попробуйте позже.';
  return msg || 'Произошла ошибка';
}

export function AuthForm() {
  const navigate = useNavigate();
  const supabase = createClient();
  const [mode, setMode]         = useState<Mode>('signin');
  const [step, setStep]         = useState<Step>('form');
  const [showPass, setShowPass] = useState(false);
  const [loading, setLoading]   = useState(false);

  // OTP step state
  const [otpEmail, setOtpEmail] = useState('');
  const [code, setCode]         = useState('');
  const [resendIn, setResendIn] = useState(0);

  const { register, handleSubmit, formState: { errors }, reset } = useForm<FormData>({
    resolver: zodResolver(schema),
  });

  const switchMode = (m: Mode) => { setMode(m); setStep('form'); reset(); };

  const startResendCooldown = () => {
    setResendIn(45);
    const t = setInterval(() => {
      setResendIn(v => {
        if (v <= 1) { clearInterval(t); return 0; }
        return v - 1;
      });
    }, 1000);
  };

  const onSubmit = async ({ email, password }: FormData) => {
    setLoading(true);
    try {
      if (mode === 'signin') {
        const { error } = await supabase.auth.signInWithPassword({ email, password });
        if (error) throw error;
        navigate('/');
      } else {
        const { data, error } = await supabase.auth.signUp({ email, password });
        if (error) throw error;
        if (data.session) {
          navigate('/');        // confirmation disabled — already signed in
        } else {
          // Supabase sent a 6-digit code → verification step.
          setOtpEmail(email);
          setCode('');
          setStep('otp');
          startResendCooldown();
          toast.success('Код отправлен на почту');
        }
      }
    } catch (err: unknown) {
      toast.error(authErrorMessage(err));
    } finally {
      setLoading(false);
    }
  };

  const verifyCode = async () => {
    if (code.trim().length < 6) { toast.error('Введите 6-значный код'); return; }
    setLoading(true);
    try {
      const { error } = await supabase.auth.verifyOtp({
        email: otpEmail, token: code.trim(), type: 'signup',
      });
      if (error) throw error;
      toast.success('Почта подтверждена');
      navigate('/');
    } catch (err: unknown) {
      toast.error(authErrorMessage(err));
    } finally {
      setLoading(false);
    }
  };

  const resend = async () => {
    if (resendIn > 0) return;
    try {
      const { error } = await supabase.auth.resend({ type: 'signup', email: otpEmail });
      if (error) throw error;
      startResendCooldown();
      toast.success('Новый код отправлен');
    } catch (err: unknown) {
      toast.error(authErrorMessage(err));
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

        <AnimatePresence mode="wait">
          {step === 'form' ? (
            <motion.div key="form-wrap"
              initial={{ opacity: 0 }} animate={{ opacity: 1 }} exit={{ opacity: 0 }}
              transition={{ duration: 0.15 }}>
              <div className={styles.tabs}>
                {(['signin', 'signup'] as Mode[]).map(m => (
                  <button key={m} type="button"
                    className={`${styles.tab} ${mode === m ? styles.tabActive : ''}`}
                    onClick={() => switchMode(m)}>
                    {m === 'signin' ? 'Войти' : 'Регистрация'}
                  </button>
                ))}
              </div>

              <form className={styles.form} onSubmit={handleSubmit(onSubmit)}>
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
              </form>
            </motion.div>
          ) : (
            <motion.div key="otp-wrap" className={styles.form}
              initial={{ opacity: 0, x: 16 }} animate={{ opacity: 1, x: 0 }} exit={{ opacity: 0 }}
              transition={{ duration: 0.18 }}>
              <div className={styles.otpHead}>
                <MailCheck size={26} className={styles.otpIcon} />
                <p className={styles.otpTitle}>Подтвердите почту</p>
                <p className={styles.otpSub}>Код отправлен на <b>{otpEmail}</b></p>
              </div>

              <div className={styles.field}>
                <label className={styles.label} htmlFor="auth-otp">Код из письма</label>
                <input id="auth-otp" inputMode="numeric" autoComplete="one-time-code"
                  maxLength={6} className={`${styles.input} ${styles.otpInput}`}
                  placeholder="000000" value={code}
                  onChange={e => setCode(e.target.value.replace(/\D/g, '').slice(0, 6))}
                  onKeyDown={e => { if (e.key === 'Enter') verifyCode(); }}
                  autoFocus />
              </div>

              <motion.button className={styles.submit} type="button"
                disabled={loading} onClick={verifyCode} whileTap={{ scale: 0.98 }}>
                {loading ? <Loader2 size={18} className={styles.spin} /> : 'Подтвердить'}
              </motion.button>

              <div className={styles.otpFoot}>
                <button type="button" className={styles.otpLink} onClick={() => setStep('form')}>
                  <ArrowLeft size={14} /> Назад
                </button>
                <button type="button" className={styles.otpLink} onClick={resend} disabled={resendIn > 0}>
                  {resendIn > 0 ? `Повторно (${resendIn})` : 'Отправить код повторно'}
                </button>
              </div>
            </motion.div>
          )}
        </AnimatePresence>

        <p className={styles.hint}>Данные синхронизируются с iOS, Android и Windows</p>
      </motion.div>
    </div>
  );
}
