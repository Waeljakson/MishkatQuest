import { ArrowLeft, CheckCircle2, Crown, Flame, LockKeyhole, Star, Target, Trophy } from 'lucide-react'
import { useEffect, useState } from 'react'; import { useNavigate } from 'react-router-dom'
import TopBar from '../components/TopBar'; import BottomNav from '../components/BottomNav'; import { getCurrentStudent, StudentDashboard } from '../lib/api'; import { supabase } from '../lib/supabase'

export default function Home(){
  const nav=useNavigate(); const [me,setMe]=useState<StudentDashboard|null>(null); const [mission,setMission]=useState<any>(null)
  useEffect(()=>{(async()=>{try{const m=await getCurrentStudent();setMe(m);if(supabase){const {data}=await supabase.from('missions').select('code,title_ar,subtitle_ar').order('sort_order').limit(1);setMission(data?.[0]||null)}}catch{}})()},[])
  const stats=me?.stats; const accuracy=stats?.total_answers?Math.round((stats.correct_answers/stats.total_answers)*100):0
  return <main className="page app-page"><TopBar xp={stats?.xp||0} coins={stats?.coins||0} streak={stats?.streak||0}/><section className="content">
    <div className="welcome-grid"><div><span className="eyebrow">المستوى {stats?.current_level||1} • المستكشف</span><h1>أهلًا {me?.full_name?.split(' ')[0]||'بك'} 👋</h1><p>{me?.grade?.name_ar||'حدد صفك'} • رحلة القدرات</p></div><div className="level-medal"><Crown/><b>{stats?.current_level||1}</b><span>{stats?.xp||0} XP</span></div></div>
    <div className="stat-grid"><article className="mini-card"><Flame/><b>{stats?.streak||0}</b><span>أيام متتالية</span></article><article className="mini-card"><Star/><b>{stats?.xp||0}</b><span>XP</span></article><article className="mini-card"><Trophy/><b>{accuracy}%</b><span>الدقة</span></article></div>
    <article className="mission-card parchment"><div><span className="eyebrow red">المهمة الحالية</span><h2>{mission?.title_ar||'استعد للمهمة الأولى'}</h2><p>{mission?.subtitle_ar||'سيظهر هنا أول تحدٍ متاح لصفك.'}</p></div><div className="mission-art"><Target size={58}/></div><button className="primary" onClick={()=>mission?nav('/mission/'+mission.code):nav('/map')}>{mission?'ابدأ المهمة':'افتح الخريطة'} <ArrowLeft/></button></article>
    <h2 className="section-title">أهداف هذا الأسبوع</h2><div className="goal-list"><div><CheckCircle2/><span>أكمل 3 مهمات</span><progress value="0" max="3"/></div><div><Target/><span>حقق دقة 80%</span><progress value={accuracy} max="80"/></div><div><LockKeyhole/><span>اهزم زعيم العالم</span><progress value="0" max="1"/></div></div>
  </section><BottomNav/></main>
}
