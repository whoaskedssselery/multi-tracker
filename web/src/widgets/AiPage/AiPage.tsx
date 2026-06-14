'use client';

import { useState, useRef, useEffect, useMemo } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { ArrowUp } from 'lucide-react';
import toast from 'react-hot-toast';
import { useAppStore } from '@/shared/store';
import { askGroq, GroqError, type ChatTurn } from '@/shared/lib/ai/groq';
import { buildContext, type AiFilter } from '@/shared/lib/ai/context';
import styles from './AiPage.module.scss';

const FILTERS: { key: AiFilter; label: string }[] = [
  { key: 'all',    label: 'Всё' },
  { key: 'train',  label: 'Тренировки' },
  { key: 'weight', label: 'Вес' },
  { key: 'tasks',  label: 'Задачи' },
];

const SUGGESTIONS = [
  'Как у меня дела на неделе?',
  'Оцени мои тренировки',
  'Что с весом?',
];

export function AiPage() {
  const messages    = useAppStore(s => s.chatMessages);
  const addMessage  = useAppStore(s => s.addChatMessage);
  const clearHistory = useAppStore(s => s.clearChatHistory);
  const groqApiKey  = useAppStore(s => s.groqApiKey);
  const aiModel     = useAppStore(s => s.preferences.aiModel);
  const weightEntries     = useAppStore(s => s.weightEntries);
  const tasks             = useAppStore(s => s.tasks);
  const setEntries        = useAppStore(s => s.setEntries);
  const exerciseTemplates = useAppStore(s => s.exerciseTemplates);

  const [filter, setFilter] = useState<AiFilter>('all');
  const [input, setInput]   = useState('');
  const [sending, setSending] = useState(false);

  const scrollRef = useRef<HTMLDivElement>(null);
  const inputRef  = useRef<HTMLTextAreaElement>(null);

  const msgs = useMemo(
    () => messages.filter(m => m.contextFilter === filter),
    [messages, filter],
  );

  const scrollToBottom = () => {
    requestAnimationFrame(() => {
      const el = scrollRef.current;
      if (el) el.scrollTo({ top: el.scrollHeight, behavior: 'smooth' });
    });
  };

  useEffect(scrollToBottom, [msgs.length, sending]);

  const send = async () => {
    const text = input.trim();
    if (!text || sending) return;

    if (!groqApiKey) {
      toast.error('Укажите Groq API ключ в Настройках');
      return;
    }

    setInput('');
    if (inputRef.current) inputRef.current.style.height = 'auto';
    setSending(true);

    // History must be captured BEFORE adding the new user message.
    const history: ChatTurn[] = messages
      .filter(m => m.contextFilter === filter)
      .slice(-20)
      .map(m => ({ role: m.role, content: m.content }));

    addMessage('user', text, filter);

    try {
      const label = FILTERS.find(f => f.key === filter)?.label ?? 'Всё';
      const ctx = buildContext(filter, {
        weightEntries, tasks, setEntries, exerciseTemplates,
      });
      const prompt =
        `Данные из приложения (фильтр: ${label}):\n${ctx}\n\nВопрос пользователя: ${text}`;

      const reply = await askGroq({ apiKey: groqApiKey, model: aiModel, prompt, history });
      addMessage('assistant', reply, filter);
    } catch (err) {
      const msg = err instanceof GroqError ? err.message : 'Не удалось получить ответ';
      toast.error(msg);
    } finally {
      setSending(false);
    }
  };

  const onKeyDown = (e: React.KeyboardEvent<HTMLTextAreaElement>) => {
    if (e.key === 'Enter' && !e.shiftKey) {
      e.preventDefault();
      send();
    }
  };

  const autoGrow = (e: React.ChangeEvent<HTMLTextAreaElement>) => {
    setInput(e.target.value);
    const el = e.target;
    el.style.height = 'auto';
    el.style.height = `${Math.min(el.scrollHeight, 120)}px`;
  };

  return (
    <div className={styles.page}>
      <header className={styles.header}>
        <div className={styles.titleRow}>
          <div>
            <h1 className={styles.title}>ИИ-тренер</h1>
            <p className={styles.subtitle}>Чат по твоим данным — вес, тренировки, задачи</p>
          </div>
          {msgs.length > 0 && (
            <button className={styles.clearBtn} onClick={() => clearHistory(filter)}>
              Очистить
            </button>
          )}
        </div>
        <div className={styles.filters}>
          {FILTERS.map(f => (
            <button
              key={f.key}
              className={`${styles.filter} ${filter === f.key ? styles.filterActive : ''}`}
              onClick={() => setFilter(f.key)}
            >
              {f.label}
            </button>
          ))}
        </div>
      </header>

      <div className={styles.messages} ref={scrollRef}>
        {msgs.length === 0 ? (
          <div className={styles.empty}>
            <img src="/icon.svg" className={styles.emptyBadge} alt="" />
            <p className={styles.emptyTitle}>Привет! Я твой ИИ-тренер.</p>
            <p className={styles.emptySub}>Спроси что-нибудь о тренировках, весе или задачах.</p>
          </div>
        ) : (
          <div className={styles.thread}>
            <AnimatePresence initial={false}>
              {msgs.map(m => (
                <motion.div
                  key={m.id}
                  className={`${styles.row} ${m.role === 'user' ? styles.rowUser : ''}`}
                  initial={{ opacity: 0, y: 8 }}
                  animate={{ opacity: 1, y: 0 }}
                  transition={{ duration: 0.18 }}
                >
                  {m.role === 'assistant' && <div className={styles.avatar}>ИИ</div>}
                  <div className={`${styles.bubble} ${m.role === 'user' ? styles.bubbleUser : ''}`}>
                    {m.content}
                  </div>
                </motion.div>
              ))}
            </AnimatePresence>
            {sending && (
              <div className={styles.row}>
                <div className={styles.avatar}>ИИ</div>
                <div className={`${styles.bubble} ${styles.typing}`}>
                  <span /><span /><span />
                </div>
              </div>
            )}
          </div>
        )}
      </div>

      {msgs.length === 0 && (
        <div className={styles.suggestions}>
          {SUGGESTIONS.map(s => (
            <button key={s} className={styles.chip} onClick={() => setInput(s)}>
              {s}
            </button>
          ))}
        </div>
      )}

      <div className={styles.inputBar}>
        <textarea
          ref={inputRef}
          className={styles.input}
          value={input}
          onChange={autoGrow}
          onKeyDown={onKeyDown}
          rows={1}
          placeholder="Спросить..."
        />
        <button
          className={styles.send}
          onClick={send}
          disabled={sending || !input.trim()}
          aria-label="Отправить"
        >
          <ArrowUp size={18} />
        </button>
      </div>
    </div>
  );
}
