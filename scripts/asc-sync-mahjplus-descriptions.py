#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Rewrite Mahj+ product paragraphs in fastlane/metadata to match en-US.

Keeps each locale's existing SUBSCRIPTIONS legal block (EULA + privacy URLs,
prices, trial, auto-renew, 24h cancel) but:
  - replaces the old "Pro Tables / advanced-only" pitch with free-forever +
    extra practice sets + The Master Tables
  - renames residual "Pro Tables" branding to Mahj+
"""
from __future__ import annotations

import re
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent / "fastlane" / "metadata"

# heading, body — mirrors en-US product model
SECTIONS: dict[str, tuple[str, str]] = {
    "es-ES": (
        "MAHJ+ (mejora opcional)",
        "Todo lo de arriba sigue siendo gratis, para siempre. Mahj+ simplemente añade más: un set de práctica extra en cada una de las cuatro salas, con preguntas, racks y manos nuevas en los mismos ejercicios que ya usas. También abre The Master Tables, donde esperan estrategia avanzada de Charleston, una escuela de defensa y ejercicios expertos de lectura de racks para quien va más allá de lo básico. Se añaden nuevos ejercicios durante todo el año.",
    ),
    "es-MX": (
        "MAHJ+ (mejora opcional)",
        "Todo lo de arriba sigue siendo gratis, para siempre. Mahj+ simplemente añade más: un set de práctica extra en cada una de las cuatro salas, con preguntas, racks y manos nuevas en los mismos ejercicios que ya usas. También abre The Master Tables, donde esperan estrategia avanzada de Charleston, una escuela de defensa y ejercicios expertos de lectura de racks para quien va más allá de lo básico. Se agregan nuevos ejercicios durante todo el año.",
    ),
    "fr-FR": (
        "MAHJ+ (amélioration optionnelle)",
        "Tout ce qui précède reste gratuit, pour toujours. Mahj+ ajoute simplement plus : un set d'entraînement supplémentaire dans chacune des quatre salles, avec de nouvelles questions, racks et donnes dans les mêmes exercices que tu utilises déjà. Il ouvre aussi The Master Tables, où t'attendent stratégie Charleston avancée, une école de défense et des exercices experts de lecture de rack pour aller au-delà des bases. De nouveaux exercices sont ajoutés toute l'année.",
    ),
    "fr-CA": (
        "MAHJ+ (amélioration optionnelle)",
        "Tout ce qui précède reste gratuit, pour toujours. Mahj+ ajoute simplement plus : un set d'entraînement supplémentaire dans chacune des quatre salles, avec de nouvelles questions, racks et donnes dans les mêmes exercices que tu utilises déjà. Il ouvre aussi The Master Tables, où t'attendent stratégie Charleston avancée, une école de défense et des exercices experts de lecture de rack pour aller au-delà des bases. De nouveaux exercices sont ajoutés toute l'année.",
    ),
    "de-DE": (
        "MAHJ+ (optionales Upgrade)",
        "Alles oben bleibt für immer kostenlos. Mahj+ fügt einfach mehr hinzu: ein Extra-Übungssatz in jedem der vier Räume, mit neuen Fragen, Racks und Geben in denselben Drills, die du schon nutzt. Außerdem öffnet es The Master Tables – mit fortgeschrittener Charleston-Strategie, einer Verteidigungsschule und Experten-Rack-Leseübungen für alle, die über die Basics hinausgehen. Neue Drills kommen das ganze Jahr über dazu.",
    ),
    "it": (
        "MAHJ+ (upgrade opzionale)",
        "Tutto quanto sopra resta gratis, per sempre. Mahj+ aggiunge semplicemente di più: un set di pratica extra in ciascuna delle quattro stanze, con domande, rack e mani nuove negli stessi esercizi che usi già. Apre anche The Master Tables, dove ti aspettano strategia Charleston avanzata, una scuola di difesa ed esercizi esperti di lettura del rack per chi va oltre le basi. Nuovi esercizi vengono aggiunti tutto l'anno.",
    ),
    "pt-BR": (
        "MAHJ+ (upgrade opcional)",
        "Tudo acima continua grátis, para sempre. O Mahj+ simplesmente adiciona mais: um conjunto extra de prática em cada uma das quatro salas, com perguntas, racks e mãos novas nos mesmos exercícios que você já usa. Também abre The Master Tables, com estratégia avançada de Charleston, uma escola de defesa e exercícios avançados de leitura de rack para quem quer ir além do básico. Novos exercícios são adicionados o ano todo.",
    ),
    "pt-PT": (
        "MAHJ+ (upgrade opcional)",
        "Tudo acima continua grátis, para sempre. O Mahj+ simplesmente acrescenta mais: um conjunto extra de prática em cada uma das quatro salas, com perguntas, racks e mãos novas nos mesmos exercícios que já usas. Também abre The Master Tables, com estratégia avançada de Charleston, uma escola de defesa e exercícios avançados de leitura de rack para quem quer ir além do básico. Novos exercícios são adicionados ao longo do ano.",
    ),
    "nl-NL": (
        "MAHJ+ (optionele upgrade)",
        "Alles hierboven blijft gratis, voor altijd. Mahj+ voegt gewoon meer toe: een extra oefenset in elk van de vier kamers, met nieuwe vragen, racks en delen in dezelfde drills die je al gebruikt. Het opent ook The Master Tables, met geavanceerde Charleston-strategie, een verdedigingsschool en expert rack-leesdrills voor wie verder wil dan de basis. Het hele jaar door komen er nieuwe drills bij.",
    ),
    "ja": (
        "Mahj+（オプションのアップグレード）",
        "上記の内容はすべて無料のまま、ずっと使えます。Mahj+は、その延長線上でもっと練習できる内容を追加します。4つのルームそれぞれに追加の練習セットがあり、同じドリル形式のまま新しい問題・配牌・ラックが加わります。さらに The Master Tables が開き、上級チャールストン戦略、守備スクール、上級ラック読みドリルが待っています。新しいドリルは年間を通じて追加されます。",
    ),
    "ko": (
        "Mahj+ (선택 업그레이드)",
        "위에 있는 내용은 모두 영원히 무료입니다. Mahj+는 더 많은 연습을 더할 뿐입니다. 네 개의 룸마다 추가 연습 세트가 있으며, 이미 쓰는 같은 드릴 형식에 새로운 문제·랙·딜이 들어갑니다. 또한 The Master Tables가 열리며, 고급 Charleston 전략, 수비 스쿨, 전문가급 랙 읽기 드릴이 기초를 넘어선 플레이어를 기다립니다. 새 드릴은 연중 계속 추가됩니다.",
    ),
    "zh-Hans": (
        "Mahj+（可选升级）",
        "以上内容永久免费。Mahj+只是在此基础上加练：四个练习室各多一套练习，题型、牌阵与发牌都沿用你已熟悉的训练方式，只是题目更新。同时解锁 The Master Tables，提供进阶查尔斯顿策略、防守课程，以及面向更高水平的读牌训练。全年持续更新新练习。",
    ),
    "zh-Hant": (
        "Mahj+（進階升級，選配）",
        "以上內容永久免費。Mahj+只是在此基礎上加練：四個練習室各多一套練習，題型、牌陣與發牌都沿用你已熟悉的訓練方式，只是題目更新。同時解鎖 The Master Tables，提供進階查爾斯頓策略、防守課程，以及給更高水準玩家的讀牌訓練。全年持續更新新練習。",
    ),
    "ru": (
        "MAHJ+ (дополнительное улучшение)",
        "Всё выше остаётся бесплатным навсегда. Mahj+ просто добавляет больше практики: дополнительный набор упражнений в каждой из четырёх комнат — новые вопросы, стойки и раздачи в тех же форматах, что ты уже используешь. Также открывает The Master Tables: продвинутая стратегия Charleston, школа защиты и экспертные упражнения по чтению стойки для тех, кто выходит за рамки основ. Новые упражнения добавляются весь год.",
    ),
    "uk": (
        "MAHJ+ (додаткове покращення)",
        "Усе вище залишається безкоштовним назавжди. Mahj+ просто додає більше практики: додатковий набір вправ у кожній із чотирьох кімнат — нові запитання, стійки й роздачі в тих самих форматах, що ти вже використовуєш. Також відкриває The Master Tables: просунута стратегія Charleston, школа захисту та експертні вправи з читання стійки для тих, хто виходить за межі основ. Нові вправи додаються впродовж усього року.",
    ),
    "pl": (
        "MAHJ+ (opcjonalne ulepszenie)",
        "Wszystko powyżej zostaje darmowe na zawsze. Mahj+ po prostu dodaje więcej: dodatkowy zestaw ćwiczeń w każdym z czterech pokoi — nowe pytania, racki i rozdania w tych samych formatach, których już używasz. Otwiera też The Master Tables z zaawansowaną strategią Charlestona, szkołą obrony i eksperckimi ćwiczeniami czytania stojaka dla graczy wykraczających poza podstawy. Nowe ćwiczenia dodawane są przez cały rok.",
    ),
    "sv": (
        "MAHJ+ (valfri uppgradering)",
        "Allt ovan förblir gratis, för alltid. Mahj+ lägger bara till mer: ett extra övningsset i vart och ett av de fyra rummen, med nya frågor, rack och givor i samma drillar du redan använder. Det öppnar också The Master Tables, med avancerad Charleston-strategi, en försvarsskola och expertövningar i rackläsning för dig som går bortom grunderna. Nya drillar läggs till under hela året.",
    ),
    "da": (
        "MAHJ+ (valgfri opgradering)",
        "Alt ovenfor forbliver gratis, for altid. Mahj+ tilføjer simpelthen mere: et ekstra øvelsessæt i hvert af de fire rum, med nye spørgsmål, racks og giv i de samme drills, du allerede bruger. Det åbner også The Master Tables med avanceret Charleston-strategi, en forsvarsskole og ekspertøvelser i racklæsning til dig, der går ud over det grundlæggende. Nye drills tilføjes hele året.",
    ),
    "no": (
        "MAHJ+ (valgfri oppgradering)",
        "Alt ovenfor forblir gratis, for alltid. Mahj+ legger ganske enkelt til mer: et ekstra øvelsessett i hvert av de fire rommene, med nye spørsmål, racks og giv i de samme drillene du allerede bruker. Det åpner også The Master Tables med avansert Charleston-strategi, en forsvarsskole og ekspertøvelser i racklesing for deg som går utover det grunnleggende. Nye drills legges til hele året.",
    ),
    "fi": (
        "MAHJ+ (valinnainen päivitys)",
        "Kaikki yllä oleva pysyy ilmaisena ikuisesti. Mahj+ lisää vain lisää harjoittelua: ylimääräisen harjoitussetin jokaiseen neljään huoneeseen, uusilla kysymyksillä, rakeilla ja jaoilla samoissa harjoitteissa joita jo käytät. Se avaa myös The Master Tables -osion, jossa odottavat edistyneempi Charleston-strategia, puolustuskoulu ja asiantuntijatason rackin lukuharjoitukset. Uusia harjoitteita lisätään ympäri vuoden.",
    ),
    "cs": (
        "MAHJ+ (volitelný upgrade)",
        "Vše výše zůstává navždy zdarma. Mahj+ prostě přidává víc: sadu cvičení navíc v každé ze čtyř místností — nové otázky, racky a rozdání ve stejných formátech, které už používáš. Také otevírá The Master Tables s pokročilou strategií Charlestonu, školou obrany a expertními cvičeními čtení stojanu pro hráče nad rámec základů. Nová cvičení přibývají celý rok.",
    ),
    "sk": (
        "MAHJ+ (voliteľný upgrade)",
        "Všetko vyššie ostáva navždy zadarmo. Mahj+ jednoducho pridáva viac: sadu cvičení navyše v každej zo štyroch miestností — nové otázky, racky a rozdania v rovnakých formátoch, ktoré už používaš. Tiež otvára The Master Tables s pokročilou stratégiou Charlestonu, školou obrany a expertnými cvičeniami čítania stojana pre hráčov nad rámec základov. Nové cvičenia pribúdajú celý rok.",
    ),
    "hu": (
        "MAHJ+ (opcionális fejlesztés)",
        "A fentiek mindörökre ingyenesek maradnak. A Mahj+ egyszerűen többet ad: extra gyakorlószettet mind a négy szobában — új kérdésekkel, rackekkel és osztásokkal ugyanazokban a gyakorlatokban, amiket már használsz. Megnyitja a The Master Tables részt is: haladó Charleston-stratégia, védelmi iskola és szakértő rack-olvasó gyakorlatok az alapokon túllépőknek. Új gyakorlatok egész évben érkeznek.",
    ),
    "ro": (
        "MAHJ+ (upgrade opțional)",
        "Tot ce e mai sus rămâne gratuit, pentru totdeauna. Mahj+ adaugă pur și simplu mai mult: un set extra de exerciții în fiecare din cele patru camere, cu întrebări, rack-uri și mâini noi în aceleași exerciții pe care le folosești deja. Deschide și The Master Tables, cu strategie avansată de Charleston, o școală de apărare și exerciții experte de citire a rackului pentru cine trece de nivel de bază. Exerciții noi se adaugă tot anul.",
    ),
    "hr": (
        "MAHJ+ (opcionalni upgrade)",
        "Sve gore ostaje besplatno, zauvijek. Mahj+ jednostavno dodaje više: dodatni set vježbi u svakoj od četiri sobe — nova pitanja, rackovi i dijeljenja u istim formatima koje već koristiš. Također otvara The Master Tables s naprednom Charleston strategijom, školom obrane i stručnim vježbama čitanja stalka za igrače koji idu dalje od osnova. Nove vježbe dodaju se cijele godine.",
    ),
    "sl-SI": (
        "MAHJ+ (izbirna nadgradnja)",
        "Vse zgoraj ostane brezplačno za vedno. Mahj+ preprosto doda več: dodaten nabor vaj v vsaki od štirih sob — nova vprašanja, racke in delitve v istih formatih, ki jih že uporabljaš. Odpre tudi The Master Tables z napredno strategijo Charlestona, šolo obrambe in strokovnimi vajami branja stojala za igralce, ki presegajo osnove. Nove vaje se dodajajo vse leto.",
    ),
    "el": (
        "MAHJ+ (προαιρετική αναβάθμιση)",
        "Όλα τα παραπάνω μένουν δωρεάν για πάντα. Το Mahj+ απλώς προσθέτει περισσότερη εξάσκηση: ένα επιπλέον σετ ασκήσεων σε καθένα από τα τέσσερα δωμάτια, με νέες ερωτήσεις, racks και μοιράσματα στα ίδια drills που ήδη χρησιμοποιείς. Ανοίγει επίσης το The Master Tables, με προχωρημένη στρατηγική Charleston, σχολή άμυνας και expert ασκήσεις ανάγνωσης rack για όσους ξεπερνούν τα βασικά. Νέα drills προστίθενται όλο τον χρόνο.",
    ),
    "tr": (
        "MAHJ+ (isteğe bağlı yükseltme)",
        "Yukarıdakilerin tümü sonsuza kadar ücretsiz kalır. Mahj+ yalnızca daha fazlasını ekler: dört odanın her birinde ekstra bir alıştırma seti — zaten kullandığın aynı drill formatlarında yeni sorular, raflar ve dağıtımlar. Ayrıca The Master Tables'ı açar: ileri Charleston stratejisi, bir savunma okulu ve temellerin ötesine geçen oyuncular için uzman raf okuma alıştırmaları. Yeni drill'ler yıl boyunca eklenir.",
    ),
    "th": (
        "Mahj+ (อัปเกรดเสริม)",
        "ทุกอย่างด้านบนฟรีตลอดไป Mahj+ แค่เพิ่มการฝึกให้มากขึ้น: ชุดฝึกพิเศษในทั้งสี่ห้อง พร้อมคำถาม แร็ค และมือใหม่ในรูปแบบดริลล์เดิมที่คุณใช้อยู่ และยังเปิด The Master Tables ซึ่งมีกลยุทธ์ชาร์ลสตันขั้นสูง โรงเรียนสอนเกมรับ และแบบฝึกอ่านไพ่มือระดับสูงสำหรับผู้ที่ผ่านพื้นฐานมาแล้ว มีดริลล์ใหม่เพิ่มตลอดทั้งปี",
    ),
    "vi": (
        "MAHJ+ (nâng cấp tùy chọn)",
        "Mọi thứ ở trên vẫn miễn phí mãi mãi. Mahj+ chỉ thêm nhiều hơn: một bộ luyện tập thêm trong mỗi phòng trong bốn phòng, với câu hỏi, rack và ván mới theo đúng dạng drill bạn đã dùng. Đồng thời mở The Master Tables với chiến thuật Charleston nâng cao, khóa phòng thủ và bài luyện đọc rack trình độ cao cho người chơi đã vững nền. Drill mới được thêm cả năm.",
    ),
    "id": (
        "MAHJ+ (upgrade opsional)",
        "Semua di atas tetap gratis selamanya. Mahj+ hanya menambahkan lebih banyak: satu set latihan ekstra di setiap dari empat ruangan, dengan pertanyaan, rak, dan deal baru dalam drill yang sama yang sudah kamu pakai. Juga membuka The Master Tables, dengan strategi Charleston lanjutan, sekolah pertahanan, dan latihan membaca rak tingkat ahli bagi yang sudah melewati dasar. Drill baru ditambahkan sepanjang tahun.",
    ),
    "ms": (
        "MAHJ+ (naik taraf pilihan)",
        "Semua di atas kekal percuma selamanya. Mahj+ hanya menambah lebih banyak: satu set latihan tambahan dalam setiap daripada empat bilik, dengan soalan, rak dan deal baharu dalam drill yang sama yang sudah anda guna. Ia juga membuka The Master Tables, dengan strategi Charleston lanjutan, sekolah pertahanan dan latihan baca rak tahap pakar untuk yang sudah melepasi asas. Drill baharu ditambah sepanjang tahun.",
    ),
    "ca": (
        "MAHJ+ (millora opcional)",
        "Tot el de dalt continua sent gratuït, per sempre. Mahj+ simplement afegeix més: un set de pràctica extra a cadascuna de les quatre sales, amb preguntes, racks i mans noves als mateixos exercicis que ja uses. També obre The Master Tables, amb estratègia avançada de Charleston, una escola de defensa i exercicis experts de lectura de racks per a qui va més enllà del bàsic. S'afegeixen exercicis nous durant tot l'any.",
    ),
    "ar-SA": (
        "Mahj+ (ترقية اختيارية)",
        "كل ما سبق يبقى مجانيًا إلى الأبد. تضيف Mahj+ ببساطة المزيد من التدريب: مجموعة تدريب إضافية في كل غرفة من الغرف الأربع، بأسئلة ومصفوفات وصفقات جديدة بنفس التمارين التي تستخدمها بالفعل. وتفتح أيضًا The Master Tables، حيث تنتظرك استراتيجية تشارلستون المتقدمة ومدرسة للدفاع وتمارين قراءة اليد بمستوى الخبراء لمن تجاوز الأساسيات. تُضاف تمارين جديدة على مدار العام.",
    ),
    "he": (
        "Mahj+ (שדרוג אופציונלי)",
        "כל מה שלמעלה נשאר בחינם לתמיד. Mahj+ פשוט מוסיף עוד תרגול: סט תרגול נוסף בכל אחד מארבעת החדרים, עם שאלות, ידיים וחלוקות חדשות באותם תרגילים שכבר משתמשים בהם. הוא גם פותח את The Master Tables, עם אסטרטגיית צ'רלסטון מתקדמת, בית ספר להגנה ותרגולי קריאת יד ברמת מומחה למי שכבר עבר את הבסיס. תרגולים חדשים מתווספים לאורך כל השנה.",
    ),
    "hi": (
        "MAHJ+ (वैकल्पिक अपग्रेड)",
        "ऊपर की हर चीज़ हमेशा मुफ़्त रहती है। Mahj+ सिर्फ़ और अभ्यास जोड़ता है: चारों रूम में से प्रत्येक में एक अतिरिक्त अभ्यास सेट — उन्हीं ड्रिल्स में नए सवाल, रैक और डील जो आप पहले से इस्तेमाल करते हैं। यह The Master Tables भी खोलता है, जहाँ एडवांस्ड चार्ल्सटन रणनीति, डिफेंस स्कूल और एक्सपर्ट रैक-रीडिंग अभ्यास बुनियादी स्तर से आगे के खिलाड़ियों का इंतज़ार करते हैं। पूरे साल नए ड्रिल जोड़े जाते हैं।",
    ),
    "bn-BD": (
        "MAHJ+ (ঐচ্ছিক আপগ্রেড)",
        "উপরের সবকিছু চিরকাল ফ্রি থাকবে। Mahj+ শুধু আরও অনুশীলন যোগ করে: চারটি রুমের প্রতিটিতে একটি অতিরিক্ত অনুশীলন সেট — আপনি যেসব ড্রিল ইতিমধ্যে ব্যবহার করেন সেখানেই নতুন প্রশ্ন, র‍্যাক ও ডিল। এটি The Master Tablesও খুলে দেয়, যেখানে উন্নত চার্লস্টন কৌশল, ডিফেন্স স্কুল এবং বিশেষজ্ঞ র‍্যাক-রিডিং অনুশীলন অপেক্ষা করে যারা মৌলিক স্তর পেরিয়ে এগোচ্ছেন। সারা বছর নতুন ড্রিল যোগ হয়।",
    ),
    "gu-IN": (
        "MAHJ+ (વૈકલ્પિક અપગ્રેડ)",
        "ઉપરની બધી વસ્તુઓ હંમેશા મફત રહે છે. Mahj+ ફક્ત વધુ અભ્યાસ ઉમેરે છે: ચારેય રૂમમાંથી દરેકમાં એક વધારાનો અભ્યાસ સેટ — તમે પહેલેથી વાપરતા ડ્રિલમાં નવા પ્રશ્નો, રેક અને ડીલ. તે The Master Tables પણ ખોલે છે, જ્યાં એડવાન્સ્ડ ચાર્લ્સટન રણનીતિ, ડિફેન્સ સ્કૂલ અને એક્સપર્ટ રેક-રીડિંગ અભ્યાસ પાયાથી આગળ વધનારા ખેલાડીઓની રાહ જુએ છે. આખું વર્ષ નવા ડ્રિલ ઉમેરાય છે.",
    ),
    "kn-IN": (
        "MAHJ+ (ಐಚ್ಛಿಕ ಅಪ್‌ಗ್ರೇಡ್)",
        "ಮೇಲಿನ ಎಲ್ಲವೂ ಯಾವತ್ತಿಗೂ ಉಚಿತವಾಗಿಯೇ ಇರುತ್ತದೆ. Mahj+ ಕೇವಲ ಹೆಚ್ಚು ಅಭ್ಯಾಸ ಸೇರಿಸುತ್ತದೆ: ನಾಲ್ಕು ರೂಮ್‌ಗಳಲ್ಲಿ ಪ್ರತಿಯೊಂದರಲ್ಲೂ ಹೆಚ್ಚುವರಿ ಅಭ್ಯಾಸ ಸೆಟ್ — ನೀವು ಈಗಾಗಲೇ ಬಳಸುವ ಅದೇ ಡ್ರಿಲ್‌ಗಳಲ್ಲಿ ಹೊಸ ಪ್ರಶ್ನೆಗಳು, ರ್ಯಾಕ್‌ಗಳು ಮತ್ತು ಡೀಲ್‌ಗಳು. ಇದು The Master Tables ಅನ್ನು ಸಹ ತೆರೆಯುತ್ತದೆ, ಅಲ್ಲಿ ಸುಧಾರಿತ ಚಾರ್ಲ್ಸ್ಟನ್ ತಂತ್ರ, ಡಿಫೆನ್ಸ್ ಸ್ಕೂಲ್ ಮತ್ತು ಪರಿಣತ ರ್ಯಾಕ್-ಓದುವ ಅಭ್ಯಾಸಗಳು ಮೂಲಭೂತ ಮಟ್ಟದಿಂದ ಮುಂದುವರಿಯುವವರಿಗಾಗಿ ಕಾಯುತ್ತವೆ. ವರ್ಷವಿಡೀ ಹೊಸ ಡ್ರಿಲ್‌ಗಳು ಸೇರುತ್ತವೆ.",
    ),
    "ml-IN": (
        "MAHJ+ (ഓപ്ഷണൽ അപ്‌ഗ്രേഡ്)",
        "മുകളിലുള്ളതെല്ലാം എന്നെന്നേക്കുമായി സൗജന്യമായി തുടരും. Mahj+ കൂടുതൽ പരിശീലനം മാത്രമേ ചേർക്കൂ: നാല് റൂമുകളിലും ഓരോന്നിലും അധിക പരിശീലന സെറ്റ് — നിങ്ങൾ ഇപ്പോൾ ഉപയോഗിക്കുന്ന അതേ ഡ്രില്ലുകളിൽ പുതിയ ചോദ്യങ്ങൾ, റാക്കുകൾ, ഡീലുകൾ. The Master Tables-ഉം തുറക്കുന്നു: അഡ്വാൻസ്ഡ് ചാൾസ്റ്റൺ തന്ത്രം, ഡിഫൻസ് സ്കൂൾ, അടിസ്ഥാനങ്ങൾ കടന്നവർക്കുള്ള വിദഗ്ധ റാക്ക്-റീഡിങ് അഭ്യാസങ്ങൾ. വർഷം മുഴുവൻ പുതിയ ഡ്രില്ലുകൾ ചേർക്കപ്പെടും.",
    ),
    "mr-IN": (
        "MAHJ+ (पर्यायी अपग्रेड)",
        "वरील सर्व काही कायमचे मोफत राहते. Mahj+ फक्त अधिक सराव जोडतो: चारही रूम्समध्ये प्रत्येकी एक अतिरिक्त सराव सेट — तुम्ही आधीच वापरत असलेल्या त्याच ड्रिल्समध्ये नवीन प्रश्न, रॅक आणि डील्स. तसेच The Master Tables उघडतो, जिथे अॅडव्हान्स्ड चार्ल्सटन रणनीती, डिफेन्स स्कूल आणि तज्ज्ञ रॅक-रीडिंग सराव पायाभूत पातळीपार जाणाऱ्या खेळाडूंची वाट पाहतात. वर्षभर नवीन ड्रिल जोडले जातात.",
    ),
    "or-IN": (
        "MAHJ+ (ବୈକଳ୍ପିକ ଅପଗ୍ରେଡ୍)",
        "ଉପରୋକ୍ତ ସବୁ ସବୁଦିନ ପାଇଁ ମାଗଣା ରହିବ। Mahj+ କେବଳ ଅଧିକ ଅଭ୍ୟାସ ଯୋଗ କରେ: ଚାରୋଟି ରୁମ୍ ମଧ୍ୟରୁ ପ୍ରତ୍ୟେକରେ ଗୋଟିଏ ଅତିରିକ୍ତ ଅଭ୍ୟାସ ସେଟ୍ — ଆପଣ ପୂର୍ବରୁ ବ୍ୟବହାର କରୁଥିବା ସେହି ଡ୍ରିଲ୍‌ଗୁଡ଼ିକରେ ନୂଆ ପ୍ରଶ୍ନ, ର୍ୟାକ୍ ଓ ଡିଲ୍। ଏହା The Master Tables ମଧ୍ୟ ଖୋଲେ, ଯେଉଁଠାରେ ଉନ୍ନତ Charleston ରଣନୀତି, ଡିଫେନ୍ସ ସ୍କୁଲ୍ ଓ ବିଶେଷଜ୍ଞ ର୍ୟାକ୍-ରିଡିଂ ଅଭ୍ୟାସ ମୌଳିକ ସ୍ତର ପାର ହୋଇଥିବା ଖେଳାଳିଙ୍କ ପାଇଁ ଅପେକ୍ଷା କରେ। ବର୍ଷସାରା ନୂଆ ଡ୍ରିଲ୍ ଯୋଗ ହୁଏ।",
    ),
    "pa-IN": (
        "MAHJ+ (ਵਿਕਲਪਿਕ ਅੱਪਗ੍ਰੇਡ)",
        "ਉੱਪਰ ਦੀ ਹਰ ਚੀਜ਼ ਹਮੇਸ਼ਾ ਮੁਫ਼ਤ ਰਹਿੰਦੀ ਹੈ। Mahj+ ਸਿਰਫ਼ ਹੋਰ ਅਭਿਆਸ ਜੋੜਦਾ ਹੈ: ਚਾਰਾਂ ਰੂਮਾਂ ਵਿੱਚੋਂ ਹਰ ਇੱਕ ਵਿੱਚ ਇੱਕ ਵਾਧੂ ਅਭਿਆਸ ਸੈੱਟ — ਉਨ੍ਹਾਂ ਹੀ ਡ੍ਰਿਲਜ਼ ਵਿੱਚ ਨਵੇਂ ਸਵਾਲ, ਰੈਕ ਅਤੇ ਡੀਲ ਜੋ ਤੁਸੀਂ ਪਹਿਲਾਂ ਤੋਂ ਵਰਤਦੇ ਹੋ। ਇਹ The Master Tables ਵੀ ਖੋਲਦਾ ਹੈ, ਜਿੱਥੇ ਐਡਵਾਂਸਡ ਚਾਰਲਸਟਨ ਰਣਨੀਤੀ, ਡਿਫੈਂਸ ਸਕੂਲ ਅਤੇ ਮਾਹਰ ਰੈਕ-ਰੀਡਿੰਗ ਅਭਿਆਸ ਬੁਨਿਆਦੀ ਪੱਧਰ ਤੋਂ ਅੱਗੇ ਵਧ ਰਹੇ ਖਿਡਾਰੀਆਂ ਦੀ ਉਡੀਕ ਕਰਦੇ ਹਨ। ਸਾਲ ਭਰ ਨਵੀਆਂ ਡ੍ਰਿਲਜ਼ ਜੋੜੀਆਂ ਜਾਂਦੀਆਂ ਹਨ।",
    ),
    "ta-IN": (
        "MAHJ+ (விருப்ப மேம்படுத்தல்)",
        "மேலுள்ள அனைத்தும் என்றென்றும் இலவசமாகவே இருக்கும். Mahj+ வெறும் கூடுதல் பயிற்சியைச் சேர்க்கிறது: நான்கு அறைகளிலும் ஒவ்வொன்றிலும் கூடுதல் பயிற்சி தொகுப்பு — நீங்கள் ஏற்கனவே பயன்படுத்தும் அதே டிரில்களில் புதிய கேள்விகள், ரேக்குகள், டீல்கள். இது The Master Tables-ஐயும் திறக்கிறது; அங்கு மேம்பட்ட Charleston உத்தி, பாதுகாப்புப் பள்ளி, அடிப்படைகளைத் தாண்டியவர்களுக்கான நிபுணர் ரேக்-ரீடிங் பயிற்சிகள் காத்திருக்கின்றன. ஆண்டு முழுவதும் புதிய டிரில்கள் சேர்க்கப்படும்.",
    ),
    "te-IN": (
        "MAHJ+ (ఐచ్ఛిక అప్‌గ్రేడ్)",
        "పైన ఉన్నవన్నీ ఎప్పటికీ ఉచితంగానే ఉంటాయి. Mahj+ కేవలం మరిన్ని సాధనలను జోడిస్తుంది: నాలుగు రూమ్‌ల్లో ప్రతిదానిలో అదనపు సాధన సెట్ — మీరు ఇప్పటికే ఉపయోగించే అదే డ్రిల్స్‌లో కొత్త ప్రశ్నలు, ర్యాక్‌లు, డీల్స్. ఇది The Master Tablesను కూడా తెరుస్తుంది, అక్కడ అధునాతన Charleston వ్యూహం, డిఫెన్స్ స్కూల్ మరియు నిపుణుల ర్యాక్-రీడింగ్ సాధనలు ప్రాథమిక స్థాయి దాటిన వారి కోసం వేచి ఉంటాయి. ఏడాది పొడవునా కొత్త డ్రిల్స్ జోడించబడతాయి.",
    ),
    "ur-PK": (
        "MAHJ+ (اختیاری اپگریڈ)",
        "اوپر کی ہر چیز ہمیشہ مفت رہتی ہے۔ Mahj+ صرف مزید مشق شامل کرتا ہے: چاروں کمروں میں سے ہر ایک میں ایک اضافی مشق سیٹ — انہی ڈرلز میں نئے سوالات، ریک اور ڈیل جو آپ پہلے سے استعمال کرتے ہیں۔ یہ The Master Tables بھی کھولتا ہے، جہاں ایڈوانسڈ چارلسٹن حکمتِ عملی، ڈیفنس اسکول اور ماہرانہ ریک ریڈنگ مشقیں بنیادی سطح سے آگے بڑھنے والے کھلاڑیوں کا انتظار کرتی ہیں۔ سال بھر نئی ڈرلز شامل ہوتی رہتی ہیں۔",
    ),
}

UPGRADE_RE = re.compile(
    r"(?im)^([^\n]*(?:Mahj\+|MAHJ\+|Pro Tables|PRO TABLES|"
    r"प्रो टेबल्स|প্রো টেবিলস|પ્રો ટેબલ્સ|ಪ್ರೊ ಟೇಬಲ್ಸ್|പ്രൊ ടേബിൾസ്|"
    r"ପ୍ରୋ ଟେବୁଲ୍ସ|ਪ੍ਰੋ ਟੇਬਲਜ਼|ప్రొ టేబుల్స్|பிரோ டேபிள்ஸ்|پرو ٹیبلز)"
    r"[^\n]*)\n(.+?)(?=\n\n)",
    re.DOTALL,
)

PRO_REPLACEMENTS = [
    (r"\bPro Tables\b", "Mahj+"),
    (r"\bPRO TABLES\b", "MAHJ+"),
    ("प्रो टेबल्स", "Mahj+"),
    ("প্রো টেবিলস", "Mahj+"),
    ("પ્રો ટેબલ્સ", "Mahj+"),
    ("ಪ್ರೊ ಟೇಬಲ್ಸ್", "Mahj+"),
    ("പ്രൊ ടേബിൾസ്", "Mahj+"),
    ("ପ୍ରୋ ଟେବୁଲ୍ସ", "Mahj+"),
    ("ਪ੍ਰੋ ਟੇਬਲਜ਼", "Mahj+"),
    ("ప్రొ టేబుల్స్", "Mahj+"),
    ("பிரோ டேபிள்ஸ்", "Mahj+"),
    ("پرو ٹیبلز", "Mahj+"),
]


def main() -> int:
    updated: list[str] = []
    failed: list[tuple[str, str]] = []
    for locale, (heading, body) in SECTIONS.items():
        path = ROOT / locale / "description.txt"
        if not path.exists():
            failed.append((locale, "missing file"))
            continue
        text = path.read_text(encoding="utf-8")
        m = UPGRADE_RE.search(text)
        if not m:
            failed.append((locale, "no upgrade section match"))
            continue
        text2 = text[: m.start()] + f"{heading}\n{body}" + text[m.end() :]
        for pat, repl in PRO_REPLACEMENTS:
            if pat.startswith("\\"):
                text2 = re.sub(pat, repl, text2)
            else:
                text2 = text2.replace(pat, repl)
        if not text2.endswith("\n"):
            text2 += "\n"
        path.write_text(text2, encoding="utf-8")
        updated.append(locale)

    print(f"updated {len(updated)}")
    if failed:
        print("failed:")
        for loc, why in failed:
            print(f"  {loc}: {why}")
        return 1

    leftover = []
    for p in sorted(ROOT.glob("*/description.txt")):
        t = p.read_text(encoding="utf-8")
        if re.search(r"Pro Tables|प्रो टेबल्स|প্রো টেবিলস|પ્રો ટેબલ્સ|ಪ್ರೊ ಟೇಬಲ್ಸ್|پرو ٹیبلز", t):
            leftover.append(p.parent.name)
    if leftover:
        print("still mention Pro Tables:", ", ".join(leftover))
        return 2

    # Legal sweep
    legal_gaps = []
    for p in sorted(ROOT.glob("*/description.txt")):
        t = p.read_text(encoding="utf-8")
        issues = []
        if "stdeula" not in t:
            issues.append("EULA")
        if "jackwallner.github.io/mahj/privacy-policy" not in t:
            issues.append("privacy")
        if not (("1.99" in t) or ("1,99" in t)):
            issues.append("1.99")
        if not (("9.99" in t) or ("9,99" in t)):
            issues.append("9.99")
        if not (("29.99" in t) or ("29,99" in t)):
            issues.append("29.99")
        if "24" not in t:
            issues.append("24h")
        if issues:
            legal_gaps.append(f"{p.parent.name}:{','.join(issues)}")
    print("legal gaps:", legal_gaps or "none")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
