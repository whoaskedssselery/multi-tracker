'use client';

import { useState } from 'react';
import {
  LineChart, Line, XAxis, YAxis, Tooltip, ResponsiveContainer,
  ReferenceLine, CartesianGrid,
} from 'recharts';
import { motion } from 'framer-motion';
import { formatChartDate } from '@/shared/lib/utils/format';
import type { WeightEntry } from '@/shared/types';
import styles from './WeightChart.module.scss';

type Period = '7д' | '30д' | '90д' | 'всё';
const PERIODS: Period[] = ['7д', '30д', '90д', 'всё'];

interface Props { entries: WeightEntry[]; targetWeight?: number; }

export function WeightChart({ entries, targetWeight }: Props) {
  const [period, setPeriod] = useState<Period>('30д');
  const filtered = filterByPeriod(entries, period);
  const chartData = [...filtered].reverse().map(e => ({
    date: e.date, value: e.value, label: formatChartDate(e.date),
  }));
  const latest = entries[0];
  const diff = chartData.length >= 2
    ? chartData[chartData.length - 1].value - chartData[0].value
    : null;
  const trendUp = diff !== null && diff > 0;
  const trendDown = diff !== null && diff < 0;

  return (
    <div className={styles.card}>
      <div className={styles.header}>
        <div>
          <span className={styles.caps}>ВЕС</span>
          <div className={styles.valueRow}>
            <span className={`${styles.value} mono`}>{latest ? latest.value.toFixed(1) : '—'}</span>
            <span className={styles.unit}>кг</span>
            {diff !== null && (
              <span className={`${styles.trend} ${trendUp ? styles.trendUp : trendDown ? styles.trendDown : ''}`}>
                {trendUp ? '↑' : trendDown ? '↓' : '→'} {Math.abs(diff).toFixed(1)} за {period}
              </span>
            )}
          </div>
        </div>
        <div className={styles.periods}>
          {PERIODS.map(p => (
            <motion.button key={p}
              className={`${styles.period} ${period === p ? styles.periodActive : ''}`}
              onClick={() => setPeriod(p)}
              whileTap={{ scale: 0.93 }}
            >{p}</motion.button>
          ))}
        </div>
      </div>

      <div className={styles.chart}>
        {chartData.length < 2 ? (
          <div className={styles.empty}>{entries.length === 0 ? 'Нет данных' : 'Нужно минимум 2 записи'}</div>
        ) : (
          <ResponsiveContainer width="100%" height={160}>
            <LineChart data={chartData} margin={{ top: 8, right: 4, bottom: 0, left: -20 }}>
              <CartesianGrid vertical={false} stroke="var(--color-border-soft)" strokeDasharray="3 3" />
              <XAxis dataKey="label"
                tick={{ fontSize: 10, fill: 'var(--color-text3)', fontFamily: 'IBM Plex Mono' }}
                axisLine={false} tickLine={false} interval="preserveStartEnd" />
              <YAxis
                tick={{ fontSize: 10, fill: 'var(--color-text3)', fontFamily: 'IBM Plex Mono' }}
                axisLine={false} tickLine={false} domain={['auto', 'auto']} width={40} />
              <Tooltip content={<ChartTooltip />}
                cursor={{ stroke: 'var(--color-accent)', strokeWidth: 1, strokeDasharray: '4 2' }} />
              {targetWeight && (
                <ReferenceLine y={targetWeight} stroke="var(--color-text4)" strokeDasharray="5 5" strokeWidth={1}
                  label={{ value: `цель ${targetWeight.toFixed(1)}`, position: 'insideBottomRight', fontSize: 10, fill: 'var(--color-text4)' }} />
              )}
              <Line type="monotone" dataKey="value" stroke="var(--color-accent)" strokeWidth={2}
                dot={{ r: 3.5, fill: 'var(--color-accent)', strokeWidth: 1.5, stroke: 'var(--color-surface)' }}
                activeDot={{ r: 5, fill: 'var(--color-accent-press)', stroke: 'var(--color-surface)', strokeWidth: 2 }} />
            </LineChart>
          </ResponsiveContainer>
        )}
      </div>
    </div>
  );
}

function ChartTooltip({ active, payload }: { active?: boolean; payload?: { value: number }[] }) {
  if (!active || !payload?.length) return null;
  return (
    <div className={styles.tooltip}>
      <span className="mono">{payload[0].value.toFixed(1)} кг</span>
    </div>
  );
}

function filterByPeriod(entries: WeightEntry[], period: Period) {
  if (period === 'всё') return entries;
  const days = period === '7д' ? 7 : period === '30д' ? 30 : 90;
  const cutoff = new Date(); cutoff.setDate(cutoff.getDate() - days);
  return entries.filter(e => new Date(e.date) >= cutoff);
}


