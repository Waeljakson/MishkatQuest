-- Mishkat Quest - production-oriented initial schema
-- Arabic gamified verbal abilities platform for Mishkat Schools

create extension if not exists pgcrypto;

-- ===== Types =====
do $$ begin
  create type public.app_role as enum ('student','teacher','supervisor','admin');
exception when duplicate_object then null; end $$;

do $$ begin
  create type public.question_type as enum ('mcq','odd_word','analogy','sentence_completion','context_error','reading');
exception when duplicate_object then null; end $$;

-- ===== Academic structure =====
create table if not exists public.schools (
  id uuid primary key default gen_random_uuid(),
  code text unique not null,
  name_ar text not null,
  is_active boolean not null default true,
  created_at timestamptz not null default now()
);

create table if not exists public.stages (
  id uuid primary key default gen_random_uuid(),
  code text unique not null,
  name_ar text not null,
  sort_order integer not null default 0
);

create table if not exists public.grades (
  id uuid primary key default gen_random_uuid(),
  stage_id uuid not null references public.stages(id) on delete restrict,
  code text unique not null,
  name_ar text not null,
  sort_order integer not null default 0
);

create table if not exists public.classes (
  id uuid primary key default gen_random_uuid(),
  school_id uuid not null references public.schools(id) on delete cascade,
  grade_id uuid not null references public.grades(id) on delete restrict,
  name_ar text not null,
  academic_year text,
  is_active boolean not null default true,
  unique (school_id, grade_id, name_ar, academic_year)
);

-- ===== Identity / roles =====
create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text not null,
  student_code text unique,
  role public.app_role not null default 'student',
  school_id uuid references public.schools(id) on delete set null,
  grade_id uuid references public.grades(id) on delete set null,
  class_id uuid references public.classes(id) on delete set null,
  avatar_key text not null default 'avatar-01',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.student_game_stats (
  student_id uuid primary key references public.profiles(id) on delete cascade,
  xp integer not null default 0 check (xp >= 0),
  coins integer not null default 0 check (coins >= 0),
  streak integer not null default 0 check (streak >= 0),
  current_level integer not null default 1 check (current_level >= 1),
  last_activity_date date,
  total_answers integer not null default 0,
  correct_answers integer not null default 0,
  updated_at timestamptz not null default now()
);

-- ===== Learning content =====
create table if not exists public.skills (
  id uuid primary key default gen_random_uuid(),
  code text unique not null,
  name_ar text not null,
  description_ar text,
  sort_order integer not null default 0,
  is_active boolean not null default true
);

create table if not exists public.worlds (
  id uuid primary key default gen_random_uuid(),
  code text unique not null,
  title_ar text not null,
  subtitle_ar text,
  theme_key text not null,
  sort_order integer not null default 0,
  is_active boolean not null default true
);

create table if not exists public.questions (
  id bigint generated always as identity primary key,
  grade_id uuid references public.grades(id) on delete set null,
  skill_id uuid not null references public.skills(id) on delete restrict,
  type public.question_type not null default 'mcq',
  prompt text not null,
  options jsonb not null,
  difficulty smallint not null default 1 check (difficulty between 1 and 5),
  xp integer not null default 10 check (xp >= 0),
  source_title text,
  source_page integer,
  source_ref text,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  constraint question_options_array check (jsonb_typeof(options) = 'array' and jsonb_array_length(options) between 2 and 6)
);

-- Answer keys are intentionally isolated from the public API surface.
create schema if not exists private;
revoke all on schema private from anon, authenticated;

create table if not exists private.question_keys (
  question_id bigint primary key references public.questions(id) on delete cascade,
  correct_index smallint not null check (correct_index between 0 and 5),
  explanation text not null
);

create table if not exists public.missions (
  id uuid primary key default gen_random_uuid(),
  code text unique not null,
  title_ar text not null,
  subtitle_ar text,
  world_id uuid not null references public.worlds(id) on delete restrict,
  grade_id uuid not null references public.grades(id) on delete restrict,
  skill_id uuid references public.skills(id) on delete set null,
  min_level integer not null default 1 check (min_level >= 1),
  reward_xp integer not null default 50 check (reward_xp >= 0),
  reward_coins integer not null default 25 check (reward_coins >= 0),
  pass_percent numeric(5,2) not null default 70 check (pass_percent between 0 and 100),
  sort_order integer not null default 0,
  is_active boolean not null default true
);

create table if not exists public.mission_questions (
  mission_id uuid not null references public.missions(id) on delete cascade,
  question_id bigint not null references public.questions(id) on delete cascade,
  sort_order integer not null default 0,
  primary key (mission_id, question_id)
);

-- ===== Student attempts / mastery =====
create table if not exists public.student_answers (
  id bigint generated always as identity primary key,
  student_id uuid not null references public.profiles(id) on delete cascade,
  question_id bigint not null references public.questions(id) on delete restrict,
  mission_id uuid references public.missions(id) on delete set null,
  selected_index smallint not null check (selected_index between 0 and 5),
  is_correct boolean not null,
  response_ms integer check (response_ms is null or response_ms >= 0),
  xp_earned integer not null default 0 check (xp_earned >= 0),
  answered_at timestamptz not null default now()
);

create index if not exists idx_student_answers_student_time on public.student_answers(student_id, answered_at desc);
create index if not exists idx_student_answers_question on public.student_answers(question_id);

create table if not exists public.student_mission_progress (
  student_id uuid not null references public.profiles(id) on delete cascade,
  mission_id uuid not null references public.missions(id) on delete cascade,
  attempts integer not null default 0,
  best_score numeric(5,2) not null default 0 check (best_score between 0 and 100),
  completed boolean not null default false,
  completed_at timestamptz,
  updated_at timestamptz not null default now(),
  primary key (student_id, mission_id)
);

create table if not exists public.student_skill_stats (
  student_id uuid not null references public.profiles(id) on delete cascade,
  skill_id uuid not null references public.skills(id) on delete cascade,
  attempts integer not null default 0,
  correct integer not null default 0,
  mastery numeric(5,2) not null default 0 check (mastery between 0 and 100),
  avg_response_ms integer,
  updated_at timestamptz not null default now(),
  primary key (student_id, skill_id)
);

create table if not exists public.student_review_queue (
  student_id uuid not null references public.profiles(id) on delete cascade,
  question_id bigint not null references public.questions(id) on delete cascade,
  wrong_count integer not null default 1,
  correct_after_wrong integer not null default 0,
  next_review_at timestamptz not null default now(),
  mastered boolean not null default false,
  updated_at timestamptz not null default now(),
  primary key (student_id, question_id)
);

-- ===== Rewards =====
create table if not exists public.achievements (
  id uuid primary key default gen_random_uuid(),
  code text unique not null,
  title_ar text not null,
  description_ar text,
  icon text,
  reward_xp integer not null default 0,
  reward_coins integer not null default 0,
  is_active boolean not null default true
);

create table if not exists public.student_achievements (
  student_id uuid not null references public.profiles(id) on delete cascade,
  achievement_id uuid not null references public.achievements(id) on delete cascade,
  earned_at timestamptz not null default now(),
  primary key (student_id, achievement_id)
);

create table if not exists public.daily_challenges (
  id uuid primary key default gen_random_uuid(),
  challenge_date date not null,
  title_ar text not null,
  description_ar text,
  target_kind text not null check (target_kind in ('answers','correct','streak','review')),
  target_value integer not null check (target_value > 0),
  reward_xp integer not null default 0,
  reward_coins integer not null default 0,
  unique (challenge_date, title_ar)
);

create table if not exists public.student_daily_progress (
  student_id uuid not null references public.profiles(id) on delete cascade,
  challenge_id uuid not null references public.daily_challenges(id) on delete cascade,
  progress integer not null default 0,
  completed boolean not null default false,
  completed_at timestamptz,
  primary key (student_id, challenge_id)
);

-- ===== Helper functions (security-definer to avoid recursive RLS) =====
create or replace function public.current_role()
returns public.app_role
language sql
stable
security definer
set search_path = public
as $$
  select role from public.profiles where id = auth.uid();
$$;

create or replace function public.current_grade_id()
returns uuid
language sql
stable
security definer
set search_path = public
as $$
  select grade_id from public.profiles where id = auth.uid();
$$;

create or replace function public.can_view_student(target_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select case
    when auth.uid() = target_id then true
    when public.current_role() = 'admin' then true
    when public.current_role() in ('teacher','supervisor') then
      exists (
        select 1
        from public.profiles me
        join public.profiles target on target.id = target_id
        where me.id = auth.uid()
          and me.school_id is not distinct from target.school_id
      )
    else false
  end;
$$;

-- ===== Auth bootstrap =====
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  default_school uuid;
begin
  select id into default_school from public.schools where code = 'mishkat' limit 1;

  insert into public.profiles(id, full_name, role, school_id, student_code)
  values (
    new.id,
    coalesce(nullif(new.raw_user_meta_data->>'full_name',''), split_part(coalesce(new.email,''),'@',1), 'طالب'),
    'student',
    default_school,
    nullif(new.raw_user_meta_data->>'student_code','')
  )
  on conflict (id) do nothing;

  insert into public.student_game_stats(student_id)
  values (new.id)
  on conflict (student_id) do nothing;

  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
after insert on auth.users
for each row execute procedure public.handle_new_user();

-- ===== Secure answer submission =====
create or replace function public.submit_answer(
  p_question_id bigint,
  p_mission_id uuid,
  p_selected_index smallint,
  p_response_ms integer default null
)
returns jsonb
language plpgsql
security definer
set search_path = public, private
as $$
declare
  uid uuid := auth.uid();
  q public.questions%rowtype;
  keyrow private.question_keys%rowtype;
  correct boolean;
  earned integer;
  old_attempts integer;
  new_attempts integer;
  new_correct integer;
  new_avg integer;
begin
  if uid is null then
    raise exception 'AUTH_REQUIRED';
  end if;

  select * into q from public.questions where id = p_question_id and is_active = true;
  if not found then raise exception 'QUESTION_NOT_FOUND'; end if;

  if public.current_role() = 'student'
     and q.grade_id is not null
     and q.grade_id is distinct from public.current_grade_id() then
    raise exception 'QUESTION_NOT_ALLOWED_FOR_GRADE';
  end if;

  if p_selected_index < 0 or p_selected_index >= jsonb_array_length(q.options) then
    raise exception 'INVALID_OPTION';
  end if;

  if p_mission_id is not null and not exists (
    select 1 from public.mission_questions mq
    where mq.mission_id = p_mission_id and mq.question_id = p_question_id
  ) then
    raise exception 'QUESTION_NOT_IN_MISSION';
  end if;

  select * into keyrow from private.question_keys where question_id = p_question_id;
  if not found then raise exception 'ANSWER_KEY_MISSING'; end if;

  correct := (p_selected_index = keyrow.correct_index);
  earned := case when correct then q.xp else 0 end;

  insert into public.student_answers(student_id, question_id, mission_id, selected_index, is_correct, response_ms, xp_earned)
  values(uid, p_question_id, p_mission_id, p_selected_index, correct, p_response_ms, earned);

  insert into public.student_game_stats(student_id, xp, total_answers, correct_answers, last_activity_date)
  values(uid, earned, 1, case when correct then 1 else 0 end, current_date)
  on conflict (student_id) do update set
    xp = public.student_game_stats.xp + excluded.xp,
    total_answers = public.student_game_stats.total_answers + 1,
    correct_answers = public.student_game_stats.correct_answers + excluded.correct_answers,
    last_activity_date = current_date,
    current_level = greatest(1, floor((public.student_game_stats.xp + excluded.xp) / 250.0)::int + 1),
    updated_at = now();

  select attempts, correct into old_attempts, new_correct
  from public.student_skill_stats where student_id = uid and skill_id = q.skill_id;

  if old_attempts is null then
    new_attempts := 1;
    new_correct := case when correct then 1 else 0 end;
    new_avg := p_response_ms;
  else
    new_attempts := old_attempts + 1;
    select correct + case when correct then 1 else 0 end,
           case when p_response_ms is null then avg_response_ms
                when avg_response_ms is null then p_response_ms
                else round(((avg_response_ms * old_attempts)::numeric + p_response_ms) / new_attempts)::int end
      into new_correct, new_avg
    from public.student_skill_stats where student_id = uid and skill_id = q.skill_id;
  end if;

  insert into public.student_skill_stats(student_id, skill_id, attempts, correct, mastery, avg_response_ms)
  values(uid, q.skill_id, new_attempts, new_correct, round((new_correct::numeric / new_attempts) * 100, 2), new_avg)
  on conflict (student_id, skill_id) do update set
    attempts = excluded.attempts,
    correct = excluded.correct,
    mastery = excluded.mastery,
    avg_response_ms = excluded.avg_response_ms,
    updated_at = now();

  if not correct then
    insert into public.student_review_queue(student_id, question_id, wrong_count, next_review_at, mastered)
    values(uid, p_question_id, 1, now() + interval '1 day', false)
    on conflict (student_id, question_id) do update set
      wrong_count = public.student_review_queue.wrong_count + 1,
      correct_after_wrong = 0,
      next_review_at = now() + interval '1 day',
      mastered = false,
      updated_at = now();
  elsif exists (select 1 from public.student_review_queue where student_id=uid and question_id=p_question_id and not mastered) then
    update public.student_review_queue
    set correct_after_wrong = correct_after_wrong + 1,
        mastered = (correct_after_wrong + 1 >= 2),
        next_review_at = case when correct_after_wrong + 1 >= 2 then now() + interval '30 days' else now() + interval '3 days' end,
        updated_at = now()
    where student_id=uid and question_id=p_question_id;
  end if;

  return jsonb_build_object(
    'is_correct', correct,
    'correct_index', keyrow.correct_index,
    'explanation', keyrow.explanation,
    'xp_earned', earned
  );
end;
$$;

revoke all on function public.submit_answer(bigint,uuid,smallint,integer) from public;
grant execute on function public.submit_answer(bigint,uuid,smallint,integer) to authenticated;

-- ===== RLS =====
alter table public.schools enable row level security;
alter table public.stages enable row level security;
alter table public.grades enable row level security;
alter table public.classes enable row level security;
alter table public.profiles enable row level security;
alter table public.student_game_stats enable row level security;
alter table public.skills enable row level security;
alter table public.worlds enable row level security;
alter table public.questions enable row level security;
alter table public.missions enable row level security;
alter table public.mission_questions enable row level security;
alter table public.student_answers enable row level security;
alter table public.student_mission_progress enable row level security;
alter table public.student_skill_stats enable row level security;
alter table public.student_review_queue enable row level security;
alter table public.achievements enable row level security;
alter table public.student_achievements enable row level security;
alter table public.daily_challenges enable row level security;
alter table public.student_daily_progress enable row level security;

-- Reference data
create policy "auth read schools" on public.schools for select to authenticated using (is_active);
create policy "auth read stages" on public.stages for select to authenticated using (true);
create policy "auth read grades" on public.grades for select to authenticated using (true);
create policy "auth read classes" on public.classes for select to authenticated using (is_active);
create policy "auth read skills" on public.skills for select to authenticated using (is_active);
create policy "auth read worlds" on public.worlds for select to authenticated using (is_active);
create policy "auth read achievements" on public.achievements for select to authenticated using (is_active);
create policy "auth read daily challenges" on public.daily_challenges for select to authenticated using (true);

-- Profiles / stats
create policy "profile scoped read" on public.profiles for select to authenticated using (public.can_view_student(id));
create policy "game stats scoped read" on public.student_game_stats for select to authenticated using (public.can_view_student(student_id));

-- Content: students only get their grade; staff see all
create policy "questions scoped read" on public.questions for select to authenticated using (
  is_active and (public.current_role() in ('teacher','supervisor','admin') or grade_id is null or grade_id = public.current_grade_id())
);
create policy "missions scoped read" on public.missions for select to authenticated using (
  is_active and (public.current_role() in ('teacher','supervisor','admin') or grade_id = public.current_grade_id())
);
create policy "mission questions read" on public.mission_questions for select to authenticated using (
  exists (select 1 from public.missions m where m.id = mission_id and m.is_active)
);

-- Student-owned analytics
create policy "answers scoped read" on public.student_answers for select to authenticated using (public.can_view_student(student_id));
create policy "mission progress scoped read" on public.student_mission_progress for select to authenticated using (public.can_view_student(student_id));
create policy "mission progress own insert" on public.student_mission_progress for insert to authenticated with check (student_id = auth.uid());
create policy "mission progress own update" on public.student_mission_progress for update to authenticated using (student_id = auth.uid()) with check (student_id = auth.uid());
create policy "skill stats scoped read" on public.student_skill_stats for select to authenticated using (public.can_view_student(student_id));
create policy "review queue scoped read" on public.student_review_queue for select to authenticated using (public.can_view_student(student_id));
create policy "student achievements scoped read" on public.student_achievements for select to authenticated using (public.can_view_student(student_id));
create policy "daily progress scoped read" on public.student_daily_progress for select to authenticated using (public.can_view_student(student_id));
create policy "daily progress own insert" on public.student_daily_progress for insert to authenticated with check (student_id = auth.uid());
create policy "daily progress own update" on public.student_daily_progress for update to authenticated using (student_id = auth.uid()) with check (student_id = auth.uid());

-- Admin content management
create policy "admin schools all" on public.schools for all to authenticated using (public.current_role()='admin') with check (public.current_role()='admin');
create policy "admin stages all" on public.stages for all to authenticated using (public.current_role()='admin') with check (public.current_role()='admin');
create policy "admin grades all" on public.grades for all to authenticated using (public.current_role()='admin') with check (public.current_role()='admin');
create policy "admin classes all" on public.classes for all to authenticated using (public.current_role()='admin') with check (public.current_role()='admin');
create policy "admin skills all" on public.skills for all to authenticated using (public.current_role()='admin') with check (public.current_role()='admin');
create policy "admin worlds all" on public.worlds for all to authenticated using (public.current_role()='admin') with check (public.current_role()='admin');
create policy "admin questions all" on public.questions for all to authenticated using (public.current_role()='admin') with check (public.current_role()='admin');
create policy "admin missions all" on public.missions for all to authenticated using (public.current_role()='admin') with check (public.current_role()='admin');
create policy "admin mission questions all" on public.mission_questions for all to authenticated using (public.current_role()='admin') with check (public.current_role()='admin');
create policy "admin achievements all" on public.achievements for all to authenticated using (public.current_role()='admin') with check (public.current_role()='admin');
create policy "admin daily challenges all" on public.daily_challenges for all to authenticated using (public.current_role()='admin') with check (public.current_role()='admin');

-- Base grants. No direct insert grant for student_answers; answers go through submit_answer().
revoke insert, update, delete on public.student_answers from authenticated;
revoke all on private.question_keys from anon, authenticated;

-- ===== Seed: school / stages / grades / skills / worlds =====
insert into public.schools(code,name_ar) values
('mishkat','مدارس المشكاة الأهلية')
on conflict (code) do update set name_ar=excluded.name_ar;

insert into public.stages(code,name_ar,sort_order) values
('primary','المرحلة الابتدائية',1),
('intermediate','المرحلة المتوسطة',2),
('secondary','المرحلة الثانوية',3)
on conflict (code) do update set name_ar=excluded.name_ar, sort_order=excluded.sort_order;

insert into public.grades(stage_id,code,name_ar,sort_order)
select s.id, v.code, v.name_ar, v.sort_order
from public.stages s
join (values
  ('primary','p4','الصف الرابع الابتدائي',4),
  ('primary','p5','الصف الخامس الابتدائي',5),
  ('primary','p6','الصف السادس الابتدائي',6),
  ('intermediate','m1','الصف الأول المتوسط',7),
  ('intermediate','m2','الصف الثاني المتوسط',8),
  ('intermediate','m3','الصف الثالث المتوسط',9),
  ('secondary','s1','الصف الأول الثانوي',10)
) as v(stage_code,code,name_ar,sort_order) on v.stage_code=s.code
on conflict (code) do update set name_ar=excluded.name_ar, sort_order=excluded.sort_order, stage_id=excluded.stage_id;

insert into public.skills(code,name_ar,description_ar,sort_order) values
('vocab','معاني المفردات','فهم دلالة الكلمة واختيار المعنى الأقرب',1),
('analogy','التناظر اللفظي','إدراك العلاقة بين زوجين من الألفاظ أو المفاهيم',2),
('sentence','إكمال الجمل','اختيار الكلمات التي تستقيم بها الجملة',3),
('context','الخطأ السياقي','اكتشاف الكلمة غير الملائمة لسياق الجملة',4),
('odd','الارتباط والاختلاف','اكتشاف العنصر المختلف أو العلاقة المشتركة بين العناصر',5),
('reading','استيعاب المقروء','قراءة النص وتحليل أفكاره ومعلوماته',6)
on conflict (code) do update set name_ar=excluded.name_ar, description_ar=excluded.description_ar, sort_order=excluded.sort_order;

insert into public.worlds(code,title_ar,subtitle_ar,theme_key,sort_order) values
('words','مدينة الكلمات','ابدأ الرحلة بفهم الكلمات ومعانيها','city',1),
('relations','وادي العلاقات','اكتشف الروابط الخفية بين الكلمات','valley',2),
('sentences','معبد الجمل','أكمل المعنى وافتح أبواب المعبد','temple',3),
('context','غابة السياق','تعقب الكلمات التي لا تنتمي للسياق','forest',4),
('odd','جزيرة المختلف','اكتشف الدخيل قبل انتهاء الوقت','island',5),
('reading','مكتبة الأسرار','اقرأ واستنتج وافتح أسرار النص','library',6),
('final','قلعة القدرات','المواجهة النهائية التي تجمع كل المهارات','castle',7)
on conflict (code) do update set title_ar=excluded.title_ar, subtitle_ar=excluded.subtitle_ar, theme_key=excluded.theme_key, sort_order=excluded.sort_order;

insert into public.achievements(code,title_ar,description_ar,icon,reward_xp,reward_coins) values
('eagle_eye','عين الصقر','10 إجابات صحيحة متتالية','target',100,50),
('word_hunter','صياد الكلمات','إكمال أول 50 سؤالًا','search',100,75),
('comeback','العودة القوية','إتقان 20 سؤالًا سبق الخطأ فيها','refresh',150,100),
('perfect_mission','المهمة الكاملة','إنهاء مهمة دون أي خطأ','crown',120,80)
on conflict (code) do update set title_ar=excluded.title_ar,description_ar=excluded.description_ar,reward_xp=excluded.reward_xp,reward_coins=excluded.reward_coins;
