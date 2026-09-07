import { supabase } from './supabase'

export type StudentDashboard = {
  id:string; full_name:string; role:string; avatar_key:string; student_code:string|null;
  grade?:{name_ar:string;code:string}|null;
  stats?:{xp:number;coins:number;streak:number;current_level:number;total_answers:number;correct_answers:number}|null;
}

export async function getCurrentStudent():Promise<StudentDashboard|null>{
  if(!supabase) return null
  const {data:{user}}=await supabase.auth.getUser()
  if(!user) return null
  const {data,error}=await supabase.from('profiles')
    .select('id,full_name,role,avatar_key,student_code,grade:grades(name_ar,code),stats:student_game_stats(xp,coins,streak,current_level,total_answers,correct_answers)')
    .eq('id',user.id).single()
  if(error) throw error
  const raw:any=data
  return {...raw, grade:Array.isArray(raw.grade)?raw.grade[0]:raw.grade, stats:Array.isArray(raw.stats)?raw.stats[0]:raw.stats}
}
