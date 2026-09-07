import { ArrowLeft, BookOpenCheck, Compass, Trophy } from 'lucide-react'
import { useNavigate } from 'react-router-dom'

export default function Splash() {
  const navigate = useNavigate()
  return <main className="splash-shell">
    <div className="light-orb one"/><div className="light-orb two"/>
    <section className="hero-card">
      <img className="hero-logo" src="/mishkat-logo.png" alt="شعار مدارس المشكاة"/>
      <div className="quest-badge">MISHKAT QUEST</div>
      <h1>مِشكاة Quest</h1>
      <h2>رحلة المشكاة لإتقان القدرات</h2>
      <p>فكّر • اكتشف • تحدَّ • أتقن</p>
      <div className="hero-icons">
        <span><Compass/> مهمات</span><span><BookOpenCheck/> مهارات</span><span><Trophy/> إنجازات</span>
      </div>
      <button className="primary xl" onClick={()=>navigate('/login')}>ابدأ رحلتك <ArrowLeft size={22}/></button>
    </section>
  </main>
}
