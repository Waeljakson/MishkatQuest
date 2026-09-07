import { LockKeyhole, Mail, Sparkles, UserRound, Hash, GraduationCap } from 'lucide-react'
import { FormEvent, useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { supabase, supabaseConfigured } from '../lib/supabase'

const grades=[
  ['p4','الرابع الابتدائي'],['p5','الخامس الابتدائي'],['p6','السادس الابتدائي'],
  ['m1','الأول المتوسط'],['m2','الثاني المتوسط'],['m3','الثالث المتوسط'],['s1','الأول الثانوي']
] as const

export default function Login() {
  const nav = useNavigate()
  const [mode,setMode]=useState<'login'|'signup'>('login')
  const [email,setEmail]=useState(''); const [password,setPassword]=useState('')
  const [fullName,setFullName]=useState(''); const [studentCode,setStudentCode]=useState(''); const [gradeCode,setGradeCode]=useState('s1')
  const [msg,setMsg]=useState(''); const [busy,setBusy]=useState(false)

  async function submit(e:FormEvent){
    e.preventDefault(); setMsg(''); setBusy(true)
    try{
      if(!supabaseConfigured || !supabase){ localStorage.setItem('mq-demo','1'); nav('/'); return }
      if(mode==='login'){
        const {error}=await supabase.auth.signInWithPassword({email,password})
        if(error) throw error
        nav('/')
      }else{
        if(fullName.trim().length<3){setMsg('اكتب اسم الطالب كاملًا.');return}
        const {data,error}=await supabase.auth.signUp({
          email,password,
          options:{data:{full_name:fullName.trim(),student_code:studentCode.trim(),grade_code:gradeCode}}
        })
        if(error) throw error
        if(data.session) nav('/')
        else setMsg('تم إنشاء الحساب. افحص البريد الإلكتروني لتأكيد الحساب ثم سجّل الدخول.')
      }
    }catch(err:any){setMsg(err?.message||'تعذر إتمام العملية.')}
    finally{setBusy(false)}
  }

  return <main className="page centered">
    <section className="login-card glass">
      <img src="/mishkat-logo.png" alt="المشكاة" className="login-logo"/>
      <span className="eyebrow"><Sparkles size={16}/> بوابة الأكاديمية</span>
      <h1>{mode==='login'?'مرحبًا بك في مِشكاة Quest':'انضم إلى رحلة المشكاة'}</h1>
      <p>{mode==='login'?'سجّل دخولك لتكمل رحلتك وتجمع نقاط الخبرة.':'أنشئ حساب الطالب وحدد صفه لفتح المسار المناسب.'}</p>
      <div className="auth-switch"><button className={mode==='login'?'active':''} onClick={()=>setMode('login')}>دخول</button><button className={mode==='signup'?'active':''} onClick={()=>setMode('signup')}>حساب جديد</button></div>
      <form onSubmit={submit}>
        {mode==='signup'&&<>
          <label><UserRound size={19}/><input value={fullName} onChange={e=>setFullName(e.target.value)} placeholder="اسم الطالب الكامل"/></label>
          <label><Hash size={19}/><input dir="ltr" value={studentCode} onChange={e=>setStudentCode(e.target.value)} placeholder="الرقم/الكود الطلابي - اختياري"/></label>
          <label><GraduationCap size={19}/><select value={gradeCode} onChange={e=>setGradeCode(e.target.value)}>{grades.map(([code,name])=><option key={code} value={code}>{name}</option>)}</select></label>
        </>}
        <label><Mail size={19}/><input dir="ltr" type="email" value={email} onChange={e=>setEmail(e.target.value)} placeholder="student@mishkat.edu.sa" required/></label>
        <label><LockKeyhole size={19}/><input dir="ltr" type="password" value={password} onChange={e=>setPassword(e.target.value)} placeholder="••••••••" minLength={6} required/></label>
        {msg && <div className="error-box neutral-msg">{msg}</div>}
        <button className="primary" type="submit" disabled={busy}>{busy?'جارٍ التنفيذ...':mode==='login'?'تسجيل الدخول':'إنشاء الحساب'}</button>
      </form>
      {!supabaseConfigured && <div className="demo-note">وضع العرض التجريبي مفعل لأن إعداد Supabase غير موجود.</div>}
    </section>
  </main>
}
