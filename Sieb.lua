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
closure-Fabrik für Zeitmessung
--]]
function createTimeKeeper()
local active,completed=false,false
local time=0.0
local timetext=""
local function isactive() return active end
local function activate(a)
    active=a; completed=false
    timetext=""
end 
local function start() 
    if active then  
        completed=false
        timetext=""
        time=os.clock() 
    end 
end
local function stop() 
    if active then
        local t=os.clock()-time
        local prec = N < 770 and 0.00000000001 or 0.000001
        timetext = table.concat{"time for ",math.tointeger(N)," = ",tostring(t-t%prec)," sec"}
        completed=true
    end 
end
local function draw() 
    if completed and WIDTH > BI then
        pushStyle()
        FONT()
        fill(clr(a.infotext))
        textMode(CENTER)
        fontSize(14)
        text(timetext,(BI+WIDTH)/2,HEIGHT-1-hCell/2)
        popStyle()        
    end
end
return
{
isactive=isactive,
activate=activate,
start=start,
stop=stop,
draw=draw
}
end

--[[
Algorithmus-bezogene Objekte zurück setzen.
--]]
function algoreset()
    initSE()
    prim=1
    volldurchlauf=false
    vielfaches=1
    vorheriges=1
    aniaborted=false
    anirestart=false
    running=false   -- während eine Animation läuft ist der Wert true
    pause=false     -- zeigt an ob eine Animation aktuell läuft (false) oder pausiert (true). 
    fertig=false    -- = true,wenn das Sieben beendet ist.  
end

--[[
Die lua-Table SE ist "der! Zustand" des Siebes während der Algorithmus läuft. Sie wird hier
initialisiert. SE hat die Form {s1,s2,...,sN}: Für jede Zahl i in 1,2,...,N ist der 
aktuelle Bearbeitungszustand si von i vermerkt. (vgl. Änderung 25.04.2018 unten).
"der! Zustand" betont die Wichtigkeit des Zustandes für den Siebvorgang. Ohne eine solche
oder ähnliche Struktur kann man das Sieb des Eratosthenes nicht realisieren.
Für jede zu siebende Zahl i ist ein Individualzustand si in SE gespeichert. Dabei bedeutet:
si=0 - Als Nichtprimzahl eingestuft. Nichtprimzahlen sind 1 und alle zusammengesetzten Zahlen.
si=1 - Als Primzahl eingestuft.
si=2 - Noch nicht hinsichtlich prim/nichtprim behandelt.
25.04.2018: Die Werte 0,1,2,3 werden neuerdings in "oberen Bits" gespeichert, an "unteren Bits" 
werden im Verlauf des Sieben der kleinste echte Teiler einer Zahl gespeichert, sofern diese 
sich nicht als Primzahl herausstellt. Diese Teiler werden im Inspektionsmodus auf Nutzeranforderung
visuell präsentiert.
Ein Zugriff auf auf den Zustand einer Zahl n in SE für die Ausgabe im Gitter
erfolgt einfach mittels m(n) wobei m(n) ein Zustand aus {0,1,2} ist. Die Funktion m "weiß"
woher in den hohen Bits von SE(n) sie den Zustand dekodieren muss.

Die Zahlen n in {1,2,...,N} sind nicht in SE oder seinen Elementen gespeichert, sondern werden
durch Schleifenvariable oder Einzelangaben in den Algorithmus eingebracht. Man kann natürlich 
auch argumentieren, dass jede lua-table sowohl ihre Schlüssel als auch die zugehörigen Werte 
verwaltet. Insofern verwaltet SE auch die zu siebenden Zahlen 1,...,N - als Schlüssel.

Das Triple <N,prim,SE > ist sehr wichtig für den Ablauf des Siebens.Durch initSE() wird der 
für inen erneuten Durchlauf nötigen Startzustand hergestellt.
Das Sieb (hier als Kurzbegriff des Algorithmus's) ist dringend darauf angewiesen, dass der
Zustand im Verlauf des Siebens korrekt und insbesondere in der richtigen Reihenfolge 
bearbeitet wird. Primzahlen werden in wachsender Reihenfolge und ohne Auslassungen gefunden,
und in der Primzahl-table pt gespeichert. In SE werden die Primzahlen praktisch nochmal
in alternativer Form (codiert in einem hohen Bit von SE[i]: m(i)=1 falls i Primzahl) gespeichert.
--]]
function initSE()
local initbit=initBit()
SE={} 
SE[1] = 1    -- 1 ist keine Primzahl; m(1)=0; SE[1]=1 führt zur Gleichung 1=1*1 im Inspektionsmodus
             -- Das wird definitorisch wie in der Mathematik üblich festgelegt.
             -- Bis auf die Zahl 1 sind alle anderen Zahlen als "noch nicht behandelt" eingestuft.
for i=2,N do  SE[i]=initbit end 
end

--[[ 
Eine closure-Fabrik für makenext. Diese Funktion muss 
bei jeder Änderung von N erneut in der Form 
makenext=createMakenext() aufgerufen werden, 
um den Zustand act=1 zu erreichen.
Dies geschieht in function setN(...) in Main.lua.
makenext ist der Iterator durch den Zahlenurwald der
von einer zur nächsten Primzahl findet. Er würde nicht
weiterfinden wenn ihm nicht die Vielfach-Machete die
Sicht freischlüge. 25.05.2018:
Der Sinn dieses closures im Vergleich zur bisherigen 
Version ist größere Klarheit: Bisher war immer ein
gesonderter Funktionaufruf neustart() erforderlich, der 
den Fall das makenext() am Ende eines Siebdurchlaufs 
nochmals aufgefufen wurde abhandelte, um einen erneuten
Durchlauf zu gestatten.
Jetzt wird zum Finden der nächsten Primzahl immer
n=makenext() aufgerufen. Nach einem vollständigen
Siebdurchlauf ebenfalls, wobei makenext automatisch
von vorn beginnt - einschließlich Neu-Initialisierung 
aller erforderlichen Objekte mittels reset(). Die
closure-Fabrik createMakenext() wird hier in ziemlich
besonderer Weise aufgerufen: Ein Aufruf erfolgt aus dem 
Inneren der Return-Funktion mit Restartbenandlung.
drei andere Aufrufe erfolgen extern in setN()
und in simpleimmerWeiter() sowie animateimmerWeiter().
An den letztgenannten Stellen wird die Version mit 
Restartbehandlung produziert.
--]]
function createMakenext(a) 
local act= a or 1
local initbit=initBit()
--[[
act ist der status des Iterators makenext, er iteriert 
durch die aufsteigende Folge der Primzahlen bis N.
Die Bahn der Werte der Variablen act ist fast
ein Spiegelbild der Bahn der Werte der globalen Variablen 
prim. Nur am Ende des Siebdurchlaufs wird ihr Wert auf der 
Position N+1 geparkt, während prim niemals dort landet.
--]]
return a > N
and 
    function () -- Version mit Restartbehandlung
        --[[
        Die Version mit Restartbehandlung wird nach jedem vollen
        Siebdurchlauf von aussen durch die Siebfunktionen
        immerWeiter bzw animateimmerWeiter aktiviert.
        --]]
        if act > N then 
            act=1 -- nach einem vollen Siebdurchlauf wieder bei 1 beginnen
            local vd=volldurchlauf
            reset() -- insbesondere SE in seinen Startzustand versetzen.
            volldurchlauf=vd
            --[[
            Hier darunter wird für alle Aufrufe nach dem ersten die
            Version ohne Restartbehandlung aktiviert.
            --]]
            makenext=createMakenext(2)
        end
        local found=N+1
        for i=act+1,N do if SE[i]==initbit then found=i break end end 
        act=found
        return act
    end 
or 
    function () -- Version ohne Restartbehandlung
        local found=N+1
        for i=act+1,N do if SE[i]==initbit then found=i break end end 
        act=found
        return act        
    end
end

--[[
n als Primzahl markieren und an Primzahltable pt anhängen.
--]]
function markprim(n)
setm(n,1)
appendPrime(n)
sposTo(n) -- Position für gelben Rahmen zur Position von n bewegen.
end

--[[
Speichert in SE[i] den kleinsten Primteiler d 
von i, und "nullt" Wert in den "hohen" 
mbits=0x3000000000000000 von SE[i]
Wird in animateVielfache(...) benutzt. Der Wert
d wird nur gesetzt, wenn der Siebalgorithmus zum
ersten mal den Eintrag i in SE "besucht". Nur
dadurch ist garantiert, dass d der kleinste Teiler
von i ist. Danach hat die Marke m(i) den Wert 0.
Wird bei animateVielfache aufgerufen.
--]]
function SETm(i,d)
if m(i)==2 then SE[i]=d end  
end

--[=[
    Dies ist eine Massnahme gegen einen Absturz. Wenn der Einstellungregler 
    für die Variable N zu schnell gezogen wird, kommt es vor, dass der callback 
    setN nicht für alle Werte von N aufgerufen wird und daher #SE < N bleibt.
--]=]
function repairSE()  

    if(#SE ~= N) then
    N=math.min(#SE,N) 
    setN(N) 
    end   
end

--[[
Callback für die Schaltfläche "Einzelschritt"
--]]
function Weiter()
if su.splashRunning() then return end -- vor Beendigung des StatupScreens nicht tun.
if Animation and running then -- Bei einem "Folgeklick" auf die Schaltfläche "Einzelschritt".;
tween.resetAll() 
aniFinish()  
Animation=false
running=false 
streicheVielfache(prim) 
end
local wtr = Animation and animateWeiter or simpleWeiter
tk.start() --if timekeeping then time=os.clock() end
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
if su.splashRunning() then return end -- vor Beendigung des StatupScreens nicht tun.
volldurchlauf=true
sound(SOUND_PICKUP, 14295)
Weiter()
end


--[[
Streichen bedeutet hier mit 0 markieren und später beim Zeichen mit clr(1)
färben (rot/dunkel dunkel falls NichtPrimzahlen_Loeschen aktiv ist).
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
local n=makenext()
if prim == 1 then gr.Y=gr.yMin end
if n <= N  then markprim(n) simplestreicheVielfache(n) end            
end

--[[
Vielfache behandeln ohne Animation.
n ist hier eine Primzahl und sie ist bereits 
als solche registriert (vgl. oben simpleWeiter ).
--]]
function simplestreicheVielfache(n) 
    local initbit=initBit()
    if n==1 then return end
    k=n*n
    if k > N then
        simpleimmerWeiter()    
    else
        --[[ 
        Die in der Schleife behandelten Zahlen werden  als "nichtprim" eingestuft.
        Durch SE[i]=n werden auch die mbits von SE[i] gelöscht vgl function setm():
        Wenn die if-Bedingung eintritt ist SE[i]=0x2FFFFFFFFFFFFFFF=2^61 der Wert
        von SE[i]. der neue Wert n ist aber hier so klein, dass er die bits 61,62
        auf keinen Fall erreicht werden . Daher stehen nach der Zuweisung dort 2 
        binäre 0.
        Mit dieser Behandlung wird in SE[i] der kleinste Teiler von i gespeichert.
        Die Bedingung if SE[i]==initbit... ist zwingend notwendig.
        --]]
        for i=k,N,n do if SE[i]==initbit then SE[i]=n end end --[[ 
                                                        Schrittweite ist n, 
                                                        Schleife bleibt im Bereich der 
                                                        Vielfachen der Primzahl n.
                                                        Bei einer "Vielfach-Schleife"
                                                        kann das  if ... mehrfach auftreten,
                                                        z.B. für alle Potenzen von n.
                                                        --]]
        if volldurchlauf then Weiter() elseif anirestart then Ani(true) anirestart=false end
    end
end

--[[
Endphase des Siebens unanimiert abarbeiten, in der keine Vielfachen mehr 
gestrichen werden müssen.
Wird aufgerufen in einem Siebzustand in dem feststeht, dass alle noch nicht 
behandelten Zahlen n Primzahlen sind. das bedeutet: m(n) == 2. Der Zustand 
wird an Hand der Bedingung prim*prim > N festgemacht. Zum Anfang wird mittels
ECount() eine Vorhersage für die finale Anzahl der Primzahlen erstellt.
--]]
function simpleimmerWeiter()  -- Ohne Animation
    ECount()
    local n=makenext() 
    while n <= N  do
    markprim(n)    --als Primzahl makieren und an die Tabelle pt anhängen
    if Reanimation() then return end
    n=makenext()
    end 
    fertig=true
    makenext=createMakenext(n)
    moveLiverectToMiddle()
    wr.testWolfram(N,pr(countprimes))
    ir:adjustRange()
    zeigeInfounten()
    zeigeGridunten()
    sound(SOUND_JUMP, 9979)
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
if anirestart and ecount and countprimes >= ecount-24 then
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
local m=makenext()
if prim == 1 then gr.Y=gr.yMin end
nextprim=m
tween.play(liveid)
running=true
sposTo(prim) eposTo(nextprim)
local duration= N <= 1000 and 0.2 or 0.1
local id1=tween(duration,spos,epos,tween.easing.linear,markprim,nextprim)
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
Testet ob eine gerade laufende Animation fortgesetzt
werden soll, oder auf Nutzeranforderung (siehe oben aniAbort) 
eine unanimierte Zwischenphase eingelegt werden soll. 
Die Nutzeranforderung ist durch den Wert aniaborted=true 
signalisiert. Es gibt im Info-Bereich eine vertikal mittlere 
Zone, in die der Nutzer tippen kann, um diesen Wert zu setzen.
Ein Returnwert true signalisiert der aufrufenden Funktion die 
Fortsetzung der Animation. Ansonsten wird die unanimierte 
Funktion exe aufgerufen. Die aufgerufende Funktion muss sich in
diesem Fall selbst beenden (z.B mittels return).

In jetzigen Version(02.04.2018) wird allerdings ein 
kurzes Endstück(24 Primzahlen) des Siebens reanimiert gezeigt.
Man kann dadurch eine zeitlich lange Animationphase überspringen.
Vergleiche dazu die function Reanimation().
--]]
function aniContinue(exe,arg)
local continue=true
if Animation and aniaborted then 
        running=false Ani(false)
        aniaborted=false 
        anirestart=true -- signalisiert einen gewünschten Übergang
                        -- in die Animation in der Endphase des Siebens
        tween.stop(liveid)
        return exe(arg) -- exe gibt nil zurück
end
-- signalisiert der aufrufenden Animations-Funktion sich selbst fortzusetzen
return continue -- Als Fortsetzung kommt eine Animation
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
behandelten Zahlen Primzahlen sind. Zum Anfang wird mittels ECount() eine 
Vorhersage für die finale Anzahl der Primzahlen erstellt.
Zustand des Siebes bedeutet: Gesamtheit aller Werte der Tabelle SE + Werte von N und prim.
Nach dem Ablauf dieser Funktion hat das Sieb seinen stabilen Endzustand erreicht. 
Alle Primzahlen sind entdeckt, alle zusammengesetzten Zahlen ebenfalls.
--]]
function animateimmerWeiter() -- Mit Animation
if Animation and not running then return end
nextprim=makenext()
if nextprim > N then 
running=false 
volldurchlauf=false
fertig=true 
makenext=createMakenext(nextprim)
moveLiverectToMiddle()
sound(SOUND_JUMP, 9979)
wr.testWolfram(N,pr(countprimes))     
ir:adjustRange()
scrollInfounten()        
if gr.Y < gr.yMax then scrollGridunten() end
tween.stop(liveid)
return
end 
ECount()
if not aniContinue(simpleimmerWeiter) then return end
tween.play(liveid)
sposTo(prim) eposTo(nextprim) 
local id1=tween(0.1,spos,epos,tween.easing.linear,markprim,nextprim) -- nextprim als prim einstufen
local id2=tween.delay(0.01,animateimmerWeiter)
local id3=tween.delay(0.01,aniFinish)
return tween.sequence(id1,id2,id3)  -- hopefully a proper tail call 
end
-- Ende Funktionen für den Siebablauf: ----------------------------------------------------------------------