import { Home, Map, ShieldCheck, UserRound } from 'lucide-react'
import { NavLink } from 'react-router-dom'

export default function BottomNav() {
  const items = [
    ['/', 'الرئيسية', Home],
    ['/map', 'الرحلة', Map],
    ['/supervisor', 'المشرف', ShieldCheck],
    ['/profile', 'ملفي', UserRound],
  ] as const
  return <nav className="bottom-nav glass">
    {items.map(([to,label,Icon]) => <NavLink key={to} to={to} className={({isActive})=>isActive?'active':''}><Icon size={21}/><span>{label}</span></NavLink>)}
  </nav>
}
