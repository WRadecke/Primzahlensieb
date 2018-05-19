--# Sieb

--[[
22.04.2018 : Die Behandlung der Vielfachen hat sich geändert. In SE[i] wird
im Laufe des Siebens der kleinste Primteiler von i gespeichert, wenn i zusammengesetzt
ist. Stattdessen ist der Wert v in {0,1,2,3} der die Zahl i in SE[I] klassifiziert in
{NichtPrimzahlen,Primzahlen,nicht bearbeitet, zwillingsanzeige}  in die hohen 
mbits=0x3000000000000000 gewandert - zwei Markierungsbits.
Diese Umkodierung wird im Inspektionsmodue genutzt, um beim Antippen einer 
zusammengesetzten Zahl deren Produktdarstellung mit ihrem kleinsten Primteiler zu zeigen.
Der kleinste Primteiler wird dann eingetragen, wenn eine Zahl i in SE als noch nicht behandelt
eingetragen ist ( m(i)==2) und diese Zahl bei der Behandlung der Vielfachen "besucht" wird.
Genau in diesem Fall wird SE[]=prim gesetzt - mit der gerade aktuellen Primzahl prim.
Da das Sieb die Primzahlen in aufsteigender Reihenfolge - und lückenlos findet,
ist das der kleinste Primteiler von i.

Funktionen mit dem prefix "simple" führen keine Animation aus.
In den 3 Funktionen animateWeiter(),animateimmerWeiter() und Vielfache()
wurden (27.03.2018) proper tail calls für tween... implementiert.
Da im vorherigen Zustand die tween-Funktionen oft ihre aufrufenden Funktionenwaltet
zurück gerufen haben, sollte die Execution-Stack-Belastung drastisch reduziert worden seim.
Vergleiche 6.3 in Roberto Ierusalimschy: Programming in Lua Third Edition.

Falls in Kommentaren auf Farben verwiesen wird, beziehen sich diese auf das dunkle Farbschema.
26.04.2016: Die Funktionen für den Siebablauf wurden in die Datei Sieb.lua verlagert.
-]]


--[[ Funktionen für den Siebablauf: --------------------------------------------------------------------------
Der Siebablauf kann für den Volldurchlauf schematisch folgendermaßen beschrieben werden:
1. unanimiert:
simpleWeiter(),simplestreicheVielfache(),simpleWeiter(),simplestreicheVielfache(),...,simpleimmerWeiter()
2. animiert:
animateWeiter(),animatestreicheVielfache(),animateWeiter(),animatestreicheVielfache(),...,animateimmerWeiter()
3. Gemischt:
animiert-unanimiert-animiert mit einer schnellen unanimierten Zwichenphase

Die Funktionen rufen sich selbst nach diesem Schema auf. Der erste Aufruf erfolgt interaktiv durch den Nutzer.
Die "...immerWeiter()"-Funktionen arbeiten in de Endphase des Siebvorgangs, in der keine Vielfachen mehr
getrichen werden müssen.
Der 3.Fall ☝️ kann durch einen Nutzer-Eingiff erfolgen - vergleiche aniContinue() -  Dabei wird
ein in der Regel großer Teil der Animation "simplifiziert" bevor wieder ein animiertes Endstück folgt.
"simplifiziert" bedeutet hier: abgearbeitet durch Funktionen deren Namen den Prefix "simple" haben, 
aber auch "simplifiziert" in der Bedeutung einfach und schnell.
--]]

--[[
Die lua-Table SE ist "der! Zustand" des Siebes während der Algorithmus läuft. Sie wird hier
initialisiert. SE hat die Form {s1,s2,...,sN}: Für jede Zahl i in 1,2,...,N ist der 
aktuelle Bearbeitungszustand si von i vermerkt. 
"der! Zustand" betont die Wichtigkeit des Zustandes für den Siebvorgang. Ohne eine solche
oder ähnliche Struktur kann man das Sieb des Eratosthenes nicht realisieren.
Für jede zu siebende Zahl i ist ein Individualzustand si in SE gespeichert. Dabei bedeutet:
si=0 - Als Nichtprimzahl eingestuft. Nichtprimzahlen sind 1 und alle zusammengesetzten Zahlen.
si=1 - Als Primzahl eingestuft.
si=2 - Noch nicht hinsichtlich prim/nichtprim behandelt.
si=3 - Ist als Mitglied eines Zwillingspaars erkannt, und wird eventuell farblich anders dargestellt.
25.04.2018: Die Werte 0,1,2,3 werden neuerdings in "oberen Bits" gespeichert, an "unteren Bits" 
werden im Verlauf des Sieben der kleinste echte Teiler einer Zahl gespeichert, sofern diese 
sich nicht als Primzahl herausstellt. Diese Teiler werden im Inspektionsmodus auf Nutzeranforderung
visuell präsentiert.
Ein Zugriff auf auf den Zustand einer Zahl n in SE für die Ausgabe im Gitter
erfolgt einfach mittels m(n) wobei m(n) ein Zustand aus {0,1,2,3} ist. Die Funktion m "weiß"
wohin in den hohen Bits von SE(n) sie den Zustand dekodieren muss.

Die Zahlen n in {1,2,...,N} sind nicht in SE oder seinen Elementen gespeichert, sondern werden
durch Schleifenvariable oder Einzelangaben in den Algorithmus eingebracht. Man kann natürlich 
auch argumentieren, dass jede lua-table sowohl ihre Schlüssel als auch die zugehörigen Werte 
verwaltet. Insofern verwaltet SE auch die zu siebenden Zahlen 1,...,N - als Schlüssel.

Das Triple N,prim,SE ist sehr wichtig für den Ablauf des Siebens.Durch initSE() wird der 
Startzustand hergestellt.
Das Sieb (hier als Kurzbegriff des Algorithmus's) ist dringend darauf angewiesen, dass der
Zustand im Verlauf des Siebens korrekt und insbesondere in der richtigen Reihenfolge 
bearbeitet wird. Primzahlen werden in wachsender Reihenfolge und ohne Auslassungen gefunden,
und in der Primzahl-table pt gespeichert. In SE werden die Primzahlen praktisch nochmal
in alternativer Form (codiert in einem hohen Bit von SE[i]: m(i)=1 falls i Primzahl) gespeichert.
--]]
function initSE()
local initbit=initBit()
SE={} 
SE[1] = 1    -- 1 ist keine Primzahl; m(1)=0; führt zur Gleichung 1=1*1 im Inspektionsmodus
             -- Das wird definitorisch wie in der Mathematik üblich festgelegt.
             -- Bis auf die Zahl 1 sind alle anderen Zahlen als "noch nicht behandelt" eingestuft.
for i=2,N do  SE[i]=initbit end 
end

--[[
Sucht den nächsten (nach aktuellem prim) unbehandelten Eintrag in der 
Tabelle SE und gibt den Index found dazu zurück. 
Gibt 0 zurück falls kein solcher existiert.
Das ist die vielleicht wichtigste Hilfsfunktion für den Siebablauf.
--]]
function makenext()
    local found=0
    for i=prim+1,N do if m(i)==2 then found=i break end end
    return found  
end

--[[
n ist die zu markierende Zahl. v ist der Markierungswert. zugelassen sind v=0,1,2
--]]
function markiere(n,v)
setm(n,v) 
end

--[[
Markiert n mit v und falls v==1 ist: 
Ergänzt die Tabelle der Primzahlen pt um den gefundene Eintrag n.
Die genaue Logik dieser Funktion ist wesentlich für den korrekten
Ablauf des Siebvorgangs.
--]]
function markset(n,v)
local vv=m(n)
if vv==2 then markiere(n,v) end
if v == 1 then 
    if vv==2 then  -- gegen Doppelerfassung von Primzahlen
    appendPrime(n) -- es entsteht eine Table von Primzahlen + Begleitinformationen.
    end
    sposTo(n)
end
end

--[[
Speichert in SE[i] den kleinsten Primteiler d 
von i, und "nullt" Wert in den "hohen" 
mbits=0x3000000000000000 von SE[i]
Wird in animateVielfache(...) benutzt.
--]]
function SETm(i,d)
if m(i)==2 then SE[i]=d end  
end

--[[
Callback für die Schaltfläche "Einzelschritt"
--]]
function Weiter()
if splashRunning() then return end -- vor Beendigung des StatupScreens nicht tun.
if Animation and running then -- Bei einem "Folgeklick" auf die Schaltfläche "Einzelschritt".
if pause then PauseResume() end
tween.resetAll() 
aniFinish()  
Animation=false
running=false 
streicheVielfache(prim) 
end
local wtr = Animation and animateWeiter or simpleWeiter
if timekeeping then time=os.clock() end
wtr()  
end

--[[
Endphase des Siebens abarbeiten, in der keine Vielfachen mehr 
gestrichen werden müssen.
--]]
function immerWeiter()
local iwtr=Animation and animateimmerWeiter or simpleimmerWeiter
iwtr()
end

--[[
Callback für die Schaltfläche "Volldurchlauf"
Alles in einem Volldurchlauf ausführen - ohne Nutzereingriff.
--]]
function allessieben()
if splashRunning() then return end -- vor Beendigung des StatupScreens nicht tun.
volldurchlauf=true
sound(SOUND_PICKUP, 14295)
tween.play(liveid)
Weiter()
end


--[[
Streichen bedeutet hier mit 0 markieren und später beim Zeichen mit clr(1)
färben (rot/dunkel dunkel falls NichPrimzahlen_Loeschen aktiv ist).
--]]
function streicheVielfache(n) -- n ist eine Primzahl
    k=n*n   -- k=n*n ist erstes zu streichendes Vielfache von n
    --[[
    Dass nicht mit k=2*n begonnen wird bedarf eine Erklärung:
    Alle Vielfache m*n < n*n mit 2 <= m < n sind bereits in vorhergehenden "Streichrunden"
    gestrichen worden. Das sieht man so ein:
    Jede positive ganze Zahl m >= 2 hat einen kleinsten echten Teiler 2 <= d <= m, 
    der Primzahl ist (vgl. Bundschuh: Einführung in die Zahlentheorie, Lemma Seite 5).
    Das beruht darauf, dass es  in der Menge {1,2,...} der natürlichen Zahlen jede nichtleere
    Teilmenge ein kleinstes Element hat, also auch die Menge der echten Teiler von m.
    Da m < n angenommen wird, ist auch d < n und daher hat m*n auch den Teiler d.Dann ist m*n 
    auch ein Vielfaches von d. 
    Daher ist m*n bereits bei der Behandlung der Primzahl d gestrichen worden, also früher als bei 
    der aktuellen Behandlung von n. Die Zahl n selbst ist Primzahl und darf daher nicht
    gestrichen werden.
    Diese Tatsache ist zur Beschleunigung des Sieben vorteilhaft: Sobald das Sieb eine Primzahl
    p gefunden hat, für die p*p > N ist, kann auf das Streichen von Vielfachen von p und aller
    darauf folgenden noch nicht behandelten Zahlen verzichtet werden. Diese sind automatisch 
    Primzahlen. Das wird durch die Funktion immerWeiter() geleistet.
    --]]
    if k > N then
    -- Falls k=n*n > N ist, sind alle noch nicht behandelten Zahlen Primzahlen.
    -- Deren Vielfache sind dann auch > N und brauchen daher nicht gestrichen werden.           
    immerWeiter()
    else    -- Es gibt noch Zahlen, die zu streichen sind.
    if Animation then
        vorheriges= n
        vielfaches=k
        animateVielfache()
    else
        simplestreicheVielfache(n)
    end
    end
end

--[[
"weiter" ohne Animation.
--]]
function simpleWeiter()
neustart() -- Neustart ermöglichen
if volldurchlauf then tween.play(liveid) end
if prim == 1 then gr.Y=gr.yMin end
if prim*prim <= N then
    local n=makenext()
    if n > 0  then simplestreicheVielfache(n) end           
end  
end

--[[
Vielfache behandeln ohne Animation.
--]]
function simplestreicheVielfache(n) -- n ist hier eine Primzahl
    if n==1 then return end
    k=n*n
    if k > N then
        simpleimmerWeiter()    
    else
        markset(n,1)
        -- Die in der Schleife behandelten Zahlen sind als "nichtprim" eingestuft.
        -- Durch SE[i]=n werden auch die mbits von SE[i] gelöscht vgl function am():
        -- Wenn die if-Bedingung eintritt ist SE[i]=0x2FFFFFFFFFFFFFFF=2^61 der Wert
        -- von SE[i]. der neue Wert n ist aber hier so klein, dass er die bits 61,62
        -- auf keinen Fall erreicht. Daher stehen nach der Zuweisung dort 2 binäre 0.
        for i=k,N,n do if m(i)==2 then SE[i]=n end end --  Schrittweite ist n, 
                                                       -- Schleife bleibt im Bereich der 
                                                       -- Vielfachen von n.
                                                       -- Bei einer "Vielfach-Schleife"
                                                       -- kann das  if ... mehrfach auftreten.
        sposTo(n)
        if volldurchlauf then Weiter() elseif anirestart then Ani(true) anirestart=false end
    end
end

--[[
Endphase des Siebens unanimiert abarbeiten, in der keine Vielfachen mehr 
gestrichen werden müssen.
Wird aufgerufen in einem Siebzustand in dem feststeht, dass alle noch nicht 
behandelten Zahlen n Primzahlen sind. das bedeutet: SE[n] == 2. Der Zustand 
wird an Hand der Bedingung prim*prim > N festgemacht. Zum Anfang wird mittels
ECount() eine Vorhersage für die finale Anzahl der Primzahlen erstellt.
--]]
function simpleimmerWeiter()  -- Ohne Animation
    ECount()
    local n=makenext() -- prim -- Beim Aufruf ist n noch nicht als Primzahl gekennzeichnet
    while n > 0  do
    markset(n,1)    --als Primzahl makieren und an die Tabelle pt anhängen
    if Reanimation() then return end
    n=makenext()
    end 
    fertig=true
    moveLiverectToMiddle()
    testWolfram(N,pr(countprimes))
    adjustInfoScrollrange()
    zeigeInfounten()
    zeigeGridunten()
    sound(SOUND_JUMP, 9979)
    tween.stop(liveid)
    volldurchlauf=false 
    
    if anirestart then  anirestart=false Ani(true)  end 
end

--[[
Ermöglicht nach einer abgebrochenen Animation den Wiederanlauf der Animation
für ein Endstück - für 24 Primzahlen - innerhalb der Endphase des Siebens.
Siehe oben den Aufruf in simpleimmerWeiter().
--]]
function Reanimation()
ret=false
if anirestart and  countprimes >= ecount-24 then
    anirestart=false
    Ani(true)
    running=true
    zeigeGridunten()
    return animateimmerWeiter() -- gibt den Identifier einer tween.sequence(...) 
                                -- zurück, der als true bewertet wird.
end
return ret  
end

--[[
Wird aufgerufen beim Tippen auf die Schaltfläche "Einzelschritt".
Es wird die jeweils nächste Primzahl gefunden und als solche grün/weiss ausgegeben. 
Alle Vielfachen davon werden soweit nicht schon vorher geschehen, als zusammengesetzt 
makiert und rot ausgegeben bzw. gelöscht falls der Schiebeschalter 
"NichPrimzahlen_ Loeschen" rechts steht.
--]]
function animateWeiter() 
local m=neustart() -- Neustart ermöglichen
if prim == 1 then gr.Y=gr.yMin end
nextprim=m
tween.play(liveid)
running=true
sposTo(prim) eposTo(nextprim)
local duration= N <= 1000 and 0.2 or 0.1
local id1=tween(duration,spos,epos,tween.easing.linear,markset,nextprim,1)
local id2=nil
local id3=tween.delay(0.1,aniFinish)
vorheriges=m
vielfaches=m*m
prim=m
if vielfaches <= N then
id2=tween.delay(0.1,animateVielfache)
else
id2=tween.delay(0.01,immerWeiter)
end
return tween.sequence(id1,id2,id3) -- hopefully a proper tail call
end

--[[
Für Animation der Vielfachen: 
Übergang zum nächsten, falls nicht
abgebrochen durch Deaktivierung der
Animation.
--]]
function nextVielfaches(n)
    if running and not Animation then
        running=false
        volldurchlauf=false
        tween.stopAll()
        -- Es wird nur der laufende Einzelschritt (unanimiert) abgeschlossen.
        -- kein weiterer Volldurchlauf
        return simplestreicheVielfache(n)       
    end
    vorheriges = vielfaches
    vielfaches = vielfaches + n
end
    
--[[
Animation der Behandlung der Vielfachen.
--]]   
function animateVielfache()
if not (Animation and running) then return end
if vielfaches <= 0 or vielfaches > N then
    running=false
    sposTo(prim)
    if volldurchlauf then return Weiter() else tween.stop(liveid) return end
    -- In dieser Situation darf keinesfalls der untere tween-Zweig ausgeführt
    -- werden: return Weiter() hat das Problem behoben. Das "pure" return 
    -- muss ebenfalls sein, reicht aber nicht.
else  
    sposTo(vorheriges) eposTo(vielfaches)
end
if not  aniContinue(simplestreicheVielfache,prim) then  return end
local id1=tween(0.1,spos,epos,tween.easing.linear, SETm,vielfaches,prim)
local id2=tween.delay(0.01,nextVielfaches,prim)
local id3=tween.delay(0.01,animateVielfache) 
return tween.sequence(id1,id2,id3) -- hopefully a proper tail call
end

--[[
Endphase des Siebens animiert abarbeiten, in der keine Vielfachen mehr 
gestrichen werden müssen.
Wird aufgerufen in einem Zustand des Siebes in dem feststeht, dass alle noch nicht
behandelten Zahlen Primzahlen sind. Zum Anfang wird mittels ECount("a") eine 
Vorhersage für die finale Anzahl der Primzahlen erstellt.
Zustand des Siebes bedeutet: Gesamtheit aller Werte der Tabelle SE + Werte von N und prim.
Nach dem Ablauf dieser Funktion hat das Sieb seinen stabilen Endzustand erreicht. 
Alle Primzahlen sind entdeckt, alle zusammengesetzten Zahlen ebenfalls.
--]]
function animateimmerWeiter() -- Mit Animation
if Animation and not running then return end
nextprim=makenext()
if nextprim <= 0 then 
running=false 
volldurchlauf=false
fertig=true 
moveLiverectToMiddle()
sound(SOUND_JUMP, 9979)
testWolfram(N,pr(countprimes))     
adjustInfoScrollrange()
scrollInfounten()        
if gr.Y < gr.yMax then scrollGridunten() end
tween.stop(liveid)
return
end 
ECount("a")
if not aniContinue(simpleimmerWeiter) then return end
tween.play(liveid)
sposTo(prim) eposTo(nextprim) 
local id1=tween(0.1,spos,epos,tween.easing.linear,markset,nextprim,1) -- nextprim als prim einstufen
local id2=tween.delay(0.01,animateimmerWeiter)
local id3=tween.delay(0.01,aniFinish)
return tween.sequence(id1,id2,id3)  -- hopefully a proper tail call 
end
-- Ende Funktionen für den Siebablauf: ----------------------------------------------------------------------