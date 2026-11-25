# Generates batch-1 exercises (language + numbers) into assets/exercises/exercises_v1.json.
# Original content. Re-running replaces earlier batch-1 items (ids start with b1_).
import json,random
P='assets/exercises/exercises_v1.json'
d=[x for x in json.load(open(P,encoding='utf-8')) if not x['id'].startswith('b1_')]
AR='٠١٢٣٤٥٦٧٨٩'
def a(n): return ''.join(AR[int(c)] for c in str(n))
HINT_GEN=['فكّر شوية وجرّب تاني.']
def add(i,t,skill,lv,prompt,data,hints,explain=''):
    x={'id':'b1_'+i,'type':t,'prompt':prompt,'hints':hints,'correct':'برافو يا بطل!','wrong':'قريب، جرّب تاني.','data':data,'skill':skill,'level':lv}
    if explain: x['explain']=explain
    d.append(x)
rnd=random.Random(7)
# ---- words with distinct letters
W=[('قلم','✏️'),('بحر','🌊'),('شمس','☀️'),('نجم','⭐'),('ورد','🌹'),('جمل','🐪'),('كلب','🐶'),('فيل','🐘'),('قمر','🌙'),('سمك','🐟'),('بيت','🏠'),('عنب','🍇'),('موز','🍌'),('كتاب','📖'),('حوت','🐋'),('نمر','🐯')]
LET=list('ابتثجحخدذرزسشصضطظعغفقكلمنهوي')
# missing letter: remove the middle letter
for i,(w,e) in enumerate(W):
    k=1
    miss=w[k]; sent=' '.join(w[:k])+' ___ '+' '.join(w[k+1:])
    opts=[miss]+rnd.sample([c for c in LET if c not in w],2)
    rnd.shuffle(opts)
    add(f'ml{i}','blank','missing_letter',1+i//6,f'{e} ما الحرف الناقص؟',{'sentence':e+'  '+sent,'options':opts,'correct':opts.index(miss)},['انطق الكلمة بصوت واضح، وانتبه للحرف اللي في النص.','الكلمة هي '+w+'.'],f'الكلمة هي «{w}».')
# build word + scrambled (same words, two games)
for i,(w,e) in enumerate(W):
    letters=list(w); sh=letters[:]
    while sh==letters: rnd.shuffle(sh)
    add(f'bw{i}','ordering','build_word',1+i//6,f'{e} رتّب الحروف لتكوّن الكلمة',{'items':sh,'order':letters},['ابدأ بالحرف الأول من الكلمة.','الحرف الأول هو «'+w[0]+'».'],f'الكلمة «{w}».')
for i,(w,e) in enumerate(W[::-1]):
    letters=list(w); sh=letters[::-1]
    if len(w)>3: sh=[letters[1],letters[3],letters[0],letters[2]]
    add(f'sc{i}','ordering','scrambled',1+i//6,f'الحروف مبعثرة! {e} ما الكلمة؟',{'items':sh,'order':letters},['الصورة بتقول لك الكلمة.','نطق الكلمة بيبدأ بحرف «'+w[0]+'».'])
# same start (multi)
SS=[('ب',['🏠 بيت','🦆 بطة','🌊 بحر','🌙 قمر','🍌 موز'],[0,1,2]),
('ك',['📖 كتاب','🐶 كلب','⭐ نجم','🥤 كوب','🍇 عنب'],[0,1,3]),
('ش',['☀️ شمس','🌳 شجرة','🐪 جمل','🍵 شاي','🐟 سمك'],[0,1,3]),
('م',['🍌 موز','🌙 قمر','🏫 مدرسة','🔑 مفتاح','🐟 سمك'],[0,2,3]),
('ق',['🌙 قمر','✏️ قلم','🐱 قطة','🐪 جمل','🏰 قلعة'],[0,1,2,4]),
('ف',['🐘 فيل','🍓 فراولة','🐭 فأر','🌹 ورد','🍄 فطر'],[0,1,2,4]),
('ج',['🐪 جمل','🧀 جبنة','🏔️ جبل','🐟 سمك','🥕 جزر'],[0,1,2,4]),
('ح',['🐋 حوت','🧳 حقيبة','🐴 حصان','🌹 ورد','🍼 حليب'],[0,1,2,4]),
('ن',['⭐ نجم','🐯 نمر','🐝 نحلة','🏠 بيت','🥁 نغمة'],[0,1,2,4])]
for i,(l,o,c) in enumerate(SS):
    add(f'ss{i}','multi','same_start',1+i//4,f'اختر كل الكلمات التي تبدأ بحرف ({l})',{'options':o,'correct':c},['فيه أكتر من إجابة. اقرأ كل كلمة وانتبه لأول حرف.','الكلمة اللي بتبدأ بحرف '+l+' بنطقها بنفس الصوت في أولها.'])
SE=[('ة',['🦆 بطة','🐱 قطة','🏠 بيت','🌳 شجرة','⭐ نجم'],[0,1,3]),
('ر',['🌊 بحر','🌙 قمر','🐘 فيل','🔑 مفتاح','🥕 جزر'],[0,1,4]),
('ب',['📖 كتاب','🐶 كلب','🍇 عنب','🌙 قمر','🥤 كوب'],[0,1,2,4]),
('م',['⭐ نجم','✏️ قلم','🐪 جمل','🐟 سمك','☀️ شمس'],[0,1]),
('ت',['🏠 بيت','🐋 حوت','🌹 ورد','🐦 عصفور','🥛 زيت'],[0,1,4]),
('ل',['🐪 جمل','🐴 حصان','🕌 هلال','🥁 طبل','🪁 طفل'],[0,3]),
('د',['🌹 ورد','🧒 ولد','🐻 دب','🦁 أسد','🏴 بلد'],[0,1,3,4])]
for i,(l,o,c) in enumerate(SE):
    add(f'se{i}','multi','same_end',1+i//3,f'اختر كل الكلمات التي تنتهي بحرف ({l})',{'options':o,'correct':c},['فيه أكتر من إجابة. انطق الكلمة وركّز على صوتها الأخير.','انظر لآخر حرف في كل كلمة.'])
# pic-word matching
PW=[[('🏠','بيت'),('🌙','قمر'),('🐟','سمك')],[('🐶','كلب'),('🐘','فيل'),('🐱','قطة')],[('🍌','موز'),('🍇','عنب'),('🍎','تفاح')],[('☀️','شمس'),('⭐','نجم'),('🌊','بحر')],[('✏️','قلم'),('📖','كتاب'),('🎒','شنطة')],[('🚗','عربية'),('✈️','طيارة'),('🚲','عجلة')],[('🌹','ورد'),('🌳','شجرة'),('🌴','نخلة')],[('🍞','عيش'),('🥛','لبن'),('🧀','جبنة')]]
for i,g in enumerate(PW):
    l=[x[0] for x in g]; r=[x[1] for x in g]; rnd.shuffle(r)
    add(f'pw{i}','matching','pic_word',1+i//3,'وصّل كل صورة باسمها',{'left':l,'right':r,'pairs':{x[0]:x[1] for x in g}},['ابدأ بالصورة اللي تعرفها أكتر.','اختار الصورة ثم الكلمة اللي تناسبها.'])
# harakat
HK=[('ب',0),('ت',1),('م',2),('ك',0),('ن',1),('ل',2),('س',0),('ر',1),('ح',2)]
HN=['الفتحة','الضمة','الكسرة']
for i,(l,k) in enumerate(HK):
    forms=[l+'َ',l+'ُ',l+'ِ']
    kk=(k+i)%3
    opts=forms[:]
    add(f'hk{i}','choice','harakat',1+i//3,f'أي حرف عليه {HN[kk]}؟',{'options':opts,'correct':kk},['الفتحة فوق الحرف، والضمة فوقه صغيرة مثل الواو، والكسرة تحته.',f'ابحث عن {HN[kk]}: '+('فوق الحرف' if kk<2 else 'تحت الحرف')+'.'])
# rhyme
RH=[('كتاب','باب',['قلم','سيارة']),('نار','جار',['ماء','شمس']),('بيت','زيت',['باب','قلم']),('قلم','علم',['كتاب','شجر']),('ليل','خيل',['نهار','شمس']),('فول','طول',['عيش','لبن']),('ورد','برد',['زهرة','حب']),('شمس','أمس',['قمر','نجم']),('سور','نور',['باب','بيت'])]
for i,(w,r,o) in enumerate(RH):
    opts=[r]+o; rnd.shuffle(opts)
    add(f'rh{i}','choice','rhyme',1+i//3,f'أي كلمة تتقفّى مع «{w}»؟',{'options':opts,'correct':opts.index(r)},['القافية يعني آخر الصوت يتشابه.',f'انطق «{w}» ثم كل اختيار وقارن الآخر.'],f'«{w}» و«{r}» آخرهم واحد.')
# bigger smaller
pairs=[(2,5),(7,3),(9,4),(1,8),(12,15),(20,18),(31,29),(45,54),(60,16),(99,100),(250,205),(111,101)]
for i,(x,y) in enumerate(pairs):
    big=i%2==0
    ans=max(x,y) if big else min(x,y)
    opts=[a(x),a(y)]
    lv=1 if max(x,y)<10 else 2 if max(x,y)<100 else 3
    add(f'bs{i}','choice','bigger_smaller',lv,('أي رقم أكبر؟' if big else 'أي رقم أصغر؟'),{'options':opts,'correct':opts.index(a(ans))},['قارن الخانة الأولى من اليسار.' if lv==3 else 'الرقم الأكبر يكون بعيد أكتر على خط الأعداد.','عُد من الصفر: أيهما يصل بعد؟'])
# missing number
for i,(st,stp,pos) in enumerate([(1,1,3),(2,1,2),(5,1,4),(1,2,3),(2,2,2),(10,10,3),(5,5,4),(3,3,2),(20,5,3),(100,100,2)]):
    seq=[st+stp*j for j in range(5)]
    ans=seq[pos]
    shown=[a(v) if j!=pos else '___' for j,v in enumerate(seq)]
    opts=[ans,ans+stp,ans-stp if ans-stp>0 else ans+2*stp]; opts=list(dict.fromkeys(opts))
    rnd.shuffle(opts)
    add(f'mn{i}','blank','missing_number',1+i//4,'أكمل تسلسل الأرقام',{'sentence':' ، '.join(shown),'options':[a(o) for o in opts],'correct':opts.index(ans)},['شوف الفرق بين كل رقم والتاني.',f'كل رقم يزيد {a(stp)}.'],f'التسلسل يزيد {a(stp)} كل مرة.')
# add pics
for i,(x,y) in enumerate([(1,1),(2,1),(2,2),(3,1),(3,2),(4,2),(3,3),(5,2),(4,4),(6,3)]):
    e=['🍎','🐥','⭐','🎈','🍓'][i%5]
    s=x+y
    opts=[s,s+1,s-1]; rnd.shuffle(opts)
    add(f'ap{i}','choice','add_pics',1+i//4,f'{e*x}  +  {e*y}  =  ؟',{'options':[a(o) for o in opts],'correct':opts.index(s)},['عُد الصور كلها مع بعض.',f'ابدأ من {a(x)} وزوّد {a(y)}.'],f'{a(x)} + {a(y)} = {a(s)}')
# subtract
for i,(x,y) in enumerate([(3,1),(4,1),(5,2),(5,3),(6,2),(7,3),(8,5),(9,4),(10,6),(10,3)]):
    s=x-y
    opts=[s,s+1,s+2 if s>0 else 3]; opts=list(dict.fromkeys(opts)); rnd.shuffle(opts)
    add(f'sa{i}','choice','subtract_apples',1+i//4,f'حنين عندها {a(x)} تفاحات، أكلت {a(y)}. كام تفاحة فاضلت؟  {"🍎"*x}',{'options':[a(o) for o in opts],'correct':opts.index(s)},['الطرح يعني ننقّص. شيل التفاح اللي اتأكل.',f'ابدأ من {a(x)} وعُد للوراء {a(y)}.'],f'{a(x)} - {a(y)} = {a(s)}')
# before after
for i,n in enumerate([4,7,2,9,15,29,40,63,99,120]):
    after=i%2==0
    ans=n+1 if after else n-1
    opts=[ans,ans+2,ans-2 if ans>2 else ans+3]; opts=list(dict.fromkeys(opts)); rnd.shuffle(opts)
    add(f'ba{i}','choice','before_after',1+i//4,f'ما الرقم {"بعد" if after else "قبل"} {a(n)}؟',{'options':[a(o) for o in opts],'correct':opts.index(ans)},['الرقم اللي بعده يكبر واحد، والرقم اللي قبله يصغر واحد.',f'{"زوّد" if after else "نقّص"} واحد من {a(n)}.'])
# even odd
EO=[[2,3,4,5],[6,7,8,9],[10,11,12,13],[14,15,16,17],[20,21,22,23],[30,31,34,35],[40,43,46,49],[52,57,58,61]]
for i,g in enumerate(EO):
    items={a(n):('زوجي' if n%2==0 else 'فردي') for n in g}
    add(f'eo{i}','categorize','even_odd',1+i//3,'حط كل رقم في مكانه: زوجي ولا فردي',{'bins':['زوجي','فردي'],'items':items},['الزوجي ينقسم على اتنين من غير باقي، وينتهي بـ ٠ ٢ ٤ ٦ ٨.','الفردي ينتهي بـ ١ ٣ ٥ ٧ ٩.'])
# money
MQ=[('كام قرش في الجنيه الواحد؟',['١٠','١٠٠','١٠٠٠'],1,1),('معاك جنيهين وأبوك أعطاك جنيه. كام معاك؟',['٣','٢','١'],0,1),('ثمن اللعبة ٥ جنيه. معاك ٣. كام ناقص؟',['٢','٣','٥'],0,2),('٥ جنيه + ٥ جنيه = ؟',['١٠','٥','١٥'],0,2),('لو معاك ١٠ جنيه واشتريت بـ ٤، كام فضل؟',['٤','٦','١٤'],1,2),('ثمن الحلوى ٣ جنيه. كام ثمن ٢ حلوى؟',['٥','٦','٩'],1,3),('معاك ٢٠ جنيه. اشتريت بـ ٧. كام فضل؟',['١٣','٢٧','١٠'],0,3),('ورقة ١٠ جنيه تساوي كام ورقة ٥ جنيه؟',['اتنين','ثلاثة','واحدة'],0,3)]
for i,(p,o,c,lv) in enumerate(MQ):
    add(f'mo{i}','choice','money',lv,'🪙 '+p,{'options':o,'correct':c},['فكّر: نجمع ولا نطرح؟','اكتب العملية في دماغك واحسبها.'])
json.dump(d,open(P,'w',encoding='utf-8',newline='\n'),ensure_ascii=False,indent=1)
print(len(d))
