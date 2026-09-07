import { ReactNode, useEffect, useState } from 'react'
import { Navigate } from 'react-router-dom'
import { supabase, supabaseConfigured } from '../lib/supabase'

export default function AuthGuard({children}:{children:ReactNode}){
  const [state,setState]=useState<'loading'|'in'|'out'>(supabaseConfigured?'loading':'in')
  useEffect(()=>{
    if(!supabaseConfigured || !supabase){ setState('in'); return }
    supabase.auth.getSession().then(({data})=>setState(data.session?'in':'out'))
    const {data:sub}=supabase.auth.onAuthStateChange((_e,session)=>setState(session?'in':'out'))
    return ()=>sub.subscription.unsubscribe()
  },[])
  if(state==='loading') return <main className="page centered"><div className="glass loading-card">جارٍ فتح بوابة المشكاة...</div></main>
  if(state==='out') return <Navigate to="/login" replace/>
  return <>{children}</>
}
