export type DemoQuestion = {
  id: number
  grade: string
  skill: string
  prompt: string
  options: string[]
  correctIndex: number
  explanation: string
  difficulty: 1 | 2 | 3 | 4 | 5
  xp: number
  source: string
}

export const demoQuestions: DemoQuestion[] = [
  {
    id: 13,
    grade: 'الأول الثانوي',
    skill: 'المفردة الشاذة',
    prompt: 'حدد المفردة المختلفة عن بقية المجموعة:',
    options: ['صفير', 'عواء', 'نباح', 'حمير'],
    correctIndex: 3,
    explanation: 'الحمير من الحيوانات، بينما بقية الكلمات أصوات.',
    difficulty: 1,
    xp: 20,
    source: 'الحقيبة التأسيسية في القدرات'
  },
  {
    id: 14,
    grade: 'الأول الثانوي',
    skill: 'المفردة الشاذة',
    prompt: 'حدد المفردة المختلفة عن بقية المجموعة:',
    options: ['إملاق', 'افتقار', 'رخاء', 'شظف'],
    correctIndex: 2,
    explanation: 'الرخاء يدل على اليسر، بينما بقية الكلمات تدل على الشدة أو الفقر.',
    difficulty: 1,
    xp: 20,
    source: 'الحقيبة التأسيسية في القدرات'
  },
  {
    id: 15,
    grade: 'الأول الثانوي',
    skill: 'المفردة الشاذة',
    prompt: 'حدد المفردة المختلفة عن بقية المجموعة:',
    options: ['اندفاع', 'تقاعس', 'تخاذل', 'تراجع'],
    correctIndex: 0,
    explanation: 'الاندفاع يدل على التقدم، بينما البقية تدل على التراجع أو التخاذل.',
    difficulty: 2,
    xp: 25,
    source: 'الحقيبة التأسيسية في القدرات'
  },
  {
    id: 16,
    grade: 'الأول الثانوي',
    skill: 'المفردة الشاذة',
    prompt: 'حدد المفردة المختلفة عن بقية المجموعة:',
    options: ['حراشف', 'ريش', 'أرجل', 'صوف'],
    correctIndex: 2,
    explanation: 'الأرجل عضو، بينما بقية الكلمات أغطية لأجسام الكائنات.',
    difficulty: 2,
    xp: 25,
    source: 'الحقيبة التأسيسية في القدرات'
  },
  {
    id: 17,
    grade: 'الأول الثانوي',
    skill: 'المفردة الشاذة',
    prompt: 'حدد المفردة المختلفة عن بقية المجموعة:',
    options: ['طواف', 'سعي', 'حلق', 'صدقة'],
    correctIndex: 3,
    explanation: 'الصدقة ليست من أعمال الحج والعمرة كالبقية.',
    difficulty: 2,
    xp: 25,
    source: 'الحقيبة التأسيسية في القدرات'
  },
  {
    id: 18,
    grade: 'الأول الثانوي',
    skill: 'المفردة الشاذة',
    prompt: 'حدد المفردة المختلفة عن بقية المجموعة:',
    options: ['أمان', 'اطمئنان', 'رعدة', 'سكينة'],
    correctIndex: 2,
    explanation: 'الرعدة تدل على الخوف، بينما البقية تدل على الأمان والطمأنينة.',
    difficulty: 3,
    xp: 30,
    source: 'الحقيبة التأسيسية في القدرات'
  }
]
