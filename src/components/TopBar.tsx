import { Coins, Flame, Star } from 'lucide-react'

type Props = { xp?: number; coins?: number; streak?: number }

export default function TopBar({ xp = 1840, coins = 720, streak = 4 }: Props) {
  return (
    <div className="topbar glass">
      <div className="brand-inline">
        <img src="/mishkat-logo.png" alt="شعار المشكاة" />
        <div><strong>Mishkat Quest</strong><span>رحلة القدرات</span></div>
      </div>
      <div className="stat-row compact">
        <span><Flame size={18}/> {streak}</span>
        <span><Star size={18}/> {xp.toLocaleString('ar-SA')}</span>
        <span><Coins size={18}/> {coins.toLocaleString('ar-SA')}</span>
      </div>
    </div>
  )
}
