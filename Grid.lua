--# Grid


--[[
x,y -Koordinaten für Zahlen im Gitter (Mitte der Gitterzelle i)
--]]
function XY(i)
local w2=math.floor(wCell/2)
local y,x=math.floor((i-1)/10),(i-1)%10
x,y=x*wCell+w2,y*wCell+w2
return x,y 
end

--[[
Rechteckpositionen im Gitter für Zahlen 1,...,N , die zu sieben sind.
X(i) gibt die Position der linken Begrenzung des Gitterzelle Nr. i an.
Beim Zeichnen wird rectMode(CORNER) benutzt. Da horizontal nicht gescrollt
wird sieht man, wenn die Gitterzelle überhaupt sichtbar ist, deren linke
Begrenzung an der durch X(i) angegebenen Position.
--]]
function X(i)
    local x=(i-1)%10; x=x*wCell
    return x  
end

--[[
Y(i) gibt die Position der Gitterzelle Nr.i an.
Beim Zeichnen wird rectMode(CORNER) benutzt.
Diese y-Position wird beim Zeichnen noch an der vertikalen 
Scrollposition gr.Y gespiegelt. Das bedeutet genauer folgendes:
Y(i)  ist eine scrollneutrale y-Position der Gitterzelle Nr. i.
Für diese y-Position wird in der Software bei Bildschirmausgaben der
Übergang zu gr.Y-Y(i) vollzogen (Spiegelung an der Scrollposition).
Daher ist in Wirklichkeit gr.Y-Y(i) die y-Koordinate der unteren  
Begrenzung der Gitterzelle Nr. i . Erst die Ausgabefunktionen 
drawGrid() und drawSE() berücksichtigen die Scrollposition gr.Y .
--]]
function Y(i)
    local y=1+math.floor((i-1)/10); y=y*wCell 
    return y    
end

--[[
Returnwerte s,e werden start,end-Indizes für Ausgaben ins Gitter.
Die Werte s < e werden aus dem in der Regel größeren Bereich {1,...,N} 
ausgewählt, um Speicherzugriffe und Bildschirmausgaben zu reduzieren.
Es wird die aktuelle Scroll-Lage berücksichtigt, um gerade nur die 
Zahlen auszugeben, die aktuell sichtbar werden sollten. Die Benutzung 
der beiden Resultate s,e soll die Speicherzugriffe auf die lua-table SE 
in drawSE() bei "großen" Werten von N minimieren. Bei Werten >= 10000 
muss die Anwendung von s,e noch durch die Funktion se12() verfeinert 
werden, was in drawSE() auch passiert.
--]] 
function seGrid(c)
local rTop= gr.Y > gr.yMin and math.floor((gr.Y-gr.yMin)/wCell) or 0 -- Zeilen die oben ausgelassen werden
local s = rTop*10 +1                -- s=startindex, rTop*10 Zahlen werden ausgelassen.
local r= N > (s-1) and N-(s-1) or 0 -- noch verfügbarer Rest
local a=math.ceil(HEIGHT/wCell)*10  -- 10 mal verfügbare Zeilen im sichtbaren Bereich (aufgerundet)
r=math.min(r,a)                     -- realer Rest
local e=s-1+r                       -- e=endindex
if c then return s,e,e-s+1 else return s,e end
end

--[[
Aufteilung des Bereiches s,e=seGrid() in eventuell zwei Bereiche
s1,e1 und s2,e2. Dabei kann einer davon leer sein, spezifiziert durch 1,0
Falls wirklich zwei Bereiche entstehen gilt {s,...,e}={s1,...e1,s2,...e2}.
Es wird berücksichtigt, wo in Beziehung zu s,e die Grenze 9999 für 4-stellige
Zahlen liegt, denn Zahlen mit mehr als 4 Dezimalstellen werden anders ausgegeben.
Das Muster 1,0  spezifiziert  einen leeren Bereich. Die Bereichsgrenzen werden in
zwei for-loops benutzt, die beim Bereich 1,0 einfach nicht ausgeführt werden, 
da step=1 benutzt wird. Zwei nichtleere Bereiche werden nur im Fall 
(s <= 9999 and 9999 < e) benötigt, wie im ersten Ausdruck unten nach 
local tbl = ... benutzt.
--]]
function se12()
local NN = 9999 -- Grenze für 4-stellige Zahlen
local s,e =seGrid()
local tbl = (s <= NN and NN < e) and {s,NN,NN+1,e} or ( e <= NN and {s,e,1,0} or {1,0,s,e} )
return unpack(tbl)
end

--[[
 Farbauswahl speziell für Zahlen im Gitter.
1 <= i <= N ti=1,2 index der colortable,
wenn ti weggelassen wird dann ti=colortables.act
--]]
function CLR(i,ti) return clr(CI(i),ti) end

--[[
Zeichnen des Ausgabegitters. Die aktuelle Scrollposition wird durch gr.Y 
berücksichtigt. Es sollen nur die Gitterlinien gezeichnet werden, die auch 
sichtbar sind. Die Benutzung  von seGrid() und Y(i) machen's elegant.
--]]
function drawGrid()
    pushStyle()
    stroke(clr(a.gridlines))
    local  yy,s,e=0,seGrid()
    for y=s-10,e,10 do yy=gr.Y-Y(y); line(0,yy,GB,yy) end  -- horizontal lines ( s-10 for topmost)
    local ylow,yhigh = math.max(HEIGHT-1-Y(N),0), HEIGHT-1 -- 0 <= ylow < yhigh=HEIGHT-1                 
    for x=0,10 do line(x*wCell,ylow,x*wCell,yhigh) end     -- vertical lines
    if gr.isOpen then 
    -- rechte Begrenzung der rechten mittleren Zelle grün kennzeichnen. --
    stroke(clr(a.liveline)) line(GB,HEIGHT/2-wCell/2,GB,HEIGHT/2+wCell/2) 
    end
    popStyle()
end

--[[
Fünfstellige Zahlen im Gitter zweizeilig ausgeben. Das ist eine 
"Notlösung" für - im vorliegenden Zusammenhang - "große" Zahlen.
--]]
function drawNumberGE10000(i)
local w2,w4 = wCell/2,wCell/4
local txt=tostring(i); l=#txt
local t,r=txt:sub(1,l-3),txt:sub(l-2,l) -- zehntausende, Rest unter Tausend als Text
pushStyle()
fill(CLR(i)) 
textMode(CORNER)  
local x,y = XY(i)
text(t,x-w2,gr.Y-y) 
textMode(CENTER)
text(r,x,gr.Y-y-w4)
popStyle()
end


--[[
Zahlen farbig entsprechend des Siebzustandes in das Gitter eintragen.
Es werden nur die Gitterzelle beliefert, die sichbar sind. Angerissene 
Zellen zählen mit. Im iPad-Landschaft-Modus sind das ingesamt höchstens 240 
Zellen, im Portrait-Modus sind es 320. Die Implementierung ist darauf ausgelegt, 
dass nur die unbedingt notwendigen Ausgaben getätigt werden. 
10.04.2018: 
Ein Fehler in vorherigen Versionen hat bei "großer" Siebgröße N dazu geführt,
dass zu viele Ausgaben entstanden, und das Programm fast unbedienbar wurde,
weil die drawSE()-Funktion viel zu lange dauerte.
--]]
function drawSE()
    --[=[
        Dieser Vorspann wirkt gegen einen Absturz. Wenn der Einstellungregler 
        für die Variable N zu schnell gezogen wird, kommt es vor, dass der callback 
        setN nicht für alle Werte von N aufgerufen wird und daher #SE < N bleibt.
    --]=]
    
    if(1 < #SE and #SE < N) then     
    for i= #SE,N do SE[i] = initBit() end  
    setN(#SE) 
    end
    --------------------------------------------------------------------------------------------
    pushStyle()
    -- Die Mitte der Texte ( Textdarstellung der Zahlen ) wird in die Mitte der Gitterzellen gelegt.
    -- Die Farben der Zahlen entspricht dem aktuellen Siebzustand (0,1,2,3) der jeweiligen Zahl.
    -- Der Wert 3 ist für Primzahlzwillinge vorgesehen.
    -- Die +1 in clr(...+1) führt zu einem gültigen Index in der 4-elementigen Tabelle der Farben.
    textMode(CENTER)
    FONT()
    fontSize(gfntsize)                       
    local s1,e1,s2,e2 = se12()
    -- Eine der beiden folgenden Schleifen kann leer sein.
    for i=s1,e1 do fill(CLR(i)); local x,y=XY(i); text(i,x,gr.Y-y) end -- für i <= 9999
    for i=s2,e2 do drawNumberGE10000(i) end                            -- für 9999 < i  
    popStyle()
end

--[[
draw-function für TimedMessage-Objekt gTM.
Bestandteil des Inspektions-Modus.    
--]]
function gFunc(tbl) -- i ist Primzahl ip ist index in table pt von i
local i,ip=tbl.p,tbl.ip 
if i < 1 or i > N then return end
pushStyle()
local ti = colortables.act==2 and 1 or 2
FONT(1) -- die schlanke ( nichfette ) Schrift macht sich im Gitter besser
fontSize(gfntsize)
fill(clr(a.bg,ti))
rectMode(CORNER)
noStroke()
rect(X(i),gr.Y-Y(i),wCell,wCell)
fill(CLR(i))
textMode(CENTER)
local x,y=XY(i)
if i <= 9999 then text(i,x,gr.Y-y) else drawNumberGE10000(i) end

    local xp= x-wP/2 < 0 and X(i)+wP/2 or (x+wP/2  > GB and GB-wP/2 or x)
    fill(clr(a.bg,ti))
    rectMode(RADIUS)
    local yy=y-(wCell/2+hP/2)
    if gr.Y-yy >= HEIGHT then yy = yy + wCell+hP end 
    rect(xp,gr.Y-yy,wP/2,hP/2)
    fill(clr(a.infotext,ti))
    local txt=""
    if ip and m(i)==1 then 
        txt=tostring(ip)..". Primzahl" 
    elseif m(i)==0 then
        txt=tostring(SE[i]).."*"..tostring(math.floor(i/SE[i]))
    end 
    text(txt,xp,gr.Y-yy)
    
    if tbl.hfun then 
        fill(clr(a.bg,ti))
        rectMode(RADIUS)
        local line = math.floor((i)/10)+1
        local mx= line-3 <=0 and (line-1)*10+6 or (line-3)*10+6 -- Mitte der darüber liegenden Gitterzeile
        txt=tbl.hfun()
        local ww,hh=textSize(txt)
        noStroke()
        local xx=X(mx) if xx-ww/2 < 0 then xx = xx + (ww/2-xx)  end
        rect(xx,gr.Y-Y(mx),ww/2,hh/2)
        textMode(CENTER)
        fill(clr(a.infotext,ti))
        text(txt,xx,gr.Y-Y(mx))
    end 
    
popStyle()    
end

--[[
Anpassen des Scrollbereiches des Gitters an einen
eventuell veränderten Wert von N. Dann muss Scrollen 
ermöglicht/verboten  werden. Da kann auch notwendig 
werden, wenn die Orientierung des iPads wechselt.
--]]
function adjustGridScrollrange()
local y = gr and gr.Y or HEIGHT-1
if gr then
    gr.Y=y gr.yMin=HEIGHT-1 gr.yMax=math.max(HEIGHT-1,(math.floor((N-1)/10)+1)*wCell)
    gr.isOpen=false
    else
    gr={Y=HEIGHT-1,yMin=HEIGHT-1,yMax=math.max(HEIGHT-1,(math.floor((N-1)/10)+1)*wCell)} 
    gr.isOpen=false
end
gr.Y = gr.Y < gr.yMin and gr.yMin or gr.Y
gr.Y = gr.Y > gr.yMax and gr.yMax or gr.Y
gr.isOpen= gr.yMin < gr.yMax and true or false   
end

--[[
Vertikales Scrollen im Gitter.
Beim Scrollen wird die oberste Ausgabeposition gr.Y modifiziert.
Möglicherweise wird das Gitter mit den Zahleninhalten oberhalb
der y-Koordinate HEIGHT ins Unsichbare ausgegeben.
--]]
function scrollGrid(touch)
if 0 <= touch.x and touch.x <= GB then
    if gr.isOpen then
        local y=touch.y-touch.prevY
        gr.Y = gr.Y + y
        gr.Y = gr.Y < gr.yMin and gr.yMin or gr.Y
        gr.Y= gr.Y > gr.yMax and gr.yMax or gr.Y 
    end
end
end

--[[
Gezieltes programmiertes Scrollen - ohne Animation - zu einer angegebenen 
vertikalen Position y.tbl bezieht sich auf eine Aktion miteiner TimedMessage.
--]]
function scrollGridTo(y,tbl)
y=y < gr.yMin and gr.yMin or y
y=y > gr.yMax and gr.yMax or y
gr.Y=y
if tbl and (tbl.p or tbl.ip) then 
if tbl.p then gTM:Start(tbl) end
end
end

--[[
Animiertes Scrollen zur Position ymit anschließender Aktivierung
des TimesMessage-Objekts gTM. tbl bezieht sich auf eine Aktion mit
einer TimedMessage
Die Funktion wird innerhalb von gg(...) aufgerufen und ist ein
Bestandteil des Inspektions-Modus.
--]]
function scrollGridAni(y,tbl) 
y=y < gr.yMin and gr.yMin or y
y=y > gr.yMax and gr.yMax or y  
if tbl then
    if y~= gr.Y then 
        local  id=tween(1.0,gr, {Y=y},tween.easing.linear,gTM.Start,gTM,tbl)
        tween.play(id)  
    else
        gTM:Start(tbl)
    end 
end  
end

--[[
Animiertes Scrollen des Zahlengitters nach  ganz unten.
--]]
function scrollGridunten()  
if gr.isOpen then
    --[[ 
    Animiertes Scrollen benötigt keine gesonderte Ausführungsfunktion
    sondern wird automatisch durch drawSE() und drawGrid() ausgeführt,
    die  im Rahmen von draw() ständig aufgerufen werden.
    --]]
    local  id=tween(2.0,gr, {Y=gr.yMax},tween.easing.linear,gridscrollFinish)
    tween.play(id)
else
    volldurchlauf=false sound(SOUND_JUMP, 9979)
end   
end

--[[
Ein "tap" führt zum einem Scrollen zu einen Bereich, der der prozentualen
vertikalen Bildschirmposition touch.y zu einem sichtbaren Bereich aus dem 
Gesamtbereich in gleicher prozentualer Lage führt.
Beispiele : 
- Ein "tap" (Fingertip) im oberen Drittel des aktuell sichtbaren Gitter führt zu
  einem neuen sichtbaren Fenster im oberen Drittel des Gesamtbereichs 1,...,N.
- Ein "tap" in der Mitte führt zur Mitte des Gesamtbereichs.
- Ein "tap" im unteren Viertel führt zum unteren Viertel des Gesamtbereichs.
--]]
function tapGrid(touch)
    if 0 <= touch.x and touch.x <= GB then
        local  nn=hitGrid(touch)
        if nn > 0 then completeSEto(nn)    end
        if gr.isOpen then       
            local y=touch.y
            y=y < wCell/4 and 0 or y
            y=y > gr.yMin-wCell/4 and gr.yMin or y
            y=(HEIGHT-1-y)/(HEIGHT-1)
            y=gr.yMin+(gr.yMax-gr.yMin)*y
            scrollGridTo(y)
        end
    end
end

--[[
Bedient den Inspektionsmodus, indiesen muss "händisch" umgeschaltet werden.
Wenn eine Primzahl angetippt wird,mwird diese auch in der Primzahlliste 
gesucht und beide werden in die vertikale Mitte gescrollt - soweit das geht. 
Anschließend werden beide Elemente farblich abgesetzt angezeigt.
Wenn eine zusammengesetzte Zahl angetippt wird, wird diese in die 
vertikale Mitte gescrollt - soweit das geht. Anschließend wird diese 
Zahl zusammen mit ihrer Faktorisierung mit dem kleinsten echten Teiler
farblich abgesetzt dargestellt. Die farblich abgesetzten Darstellungen 
sind zeitlich begrenzt.
--]]
function tap1Grid(touch)
--[[
Zu tapGrid(...) umleiten, wenn Siebvorgang noch läuft.
--]]  
if ecount~=countprimes then return tapGrid(touch) end 
---------------------------------------------------------
if 0 <= touch.x and touch.x <= GB then
    gTM.running,iTM.running=false,false -- vorherige Anzeigen abbrechen
    local tblg,tbli={ani=true,tdelta=10.0},{ani=true,tdelta=10.0}
    n=hitGrid(touch); n = n==1 and 2 or n
    if n > N then return end
    local index
    tblg.p=n
    if isPrim(n) then
        index=findindex(n)
    end
    if index then tbli.ip=index gi(tbli) end  -- Inspektions-Aktion in der Primzahlliste
    gg(tblg)                                  -- Inspektions-Aktion im Gitter
end 
end

--[[
Findet beim Tippen gemäß tap1Grid(...) die benachbarte Primzahl
und  deren index in table pt. Wird zur Zeit nicht benutzt.
--]]
function nextPrim(n) -- n kommt aus hitGrid
if n < 2 then return 2,1
elseif  n >= pr(countprimes) then return pr(countprimes),countprimes
else
        while m(n)==0  and n <= N do n = n + 1 end 
        if n >= pr(countprimes) then return pr(countprimes),countprimes end
        local ip=1
        for i=1,countprimes do if pr(i)==n then ip=i break end end
        return n,ip -- n: Primzahl, ip: Index von n in der Primzahlliste
end
end

--[[
Scrollt - wenn soweit gescrollt werden kann - vertikal im Gitter 
derart,  dass Gitterzelle Nr. n in der vertikalen Mitte erscheint.
Falls der Scrollrange zu klein ist, kann die Mitte verfehlt werden.
Merkbrücke: gg ist: go in grid (to n)
--]]
function gg(tbl) 
local n,ip,ani=tbl.p,tbl.ip,tbl.ani
if n < 1 or n  > N then return end
if isPrim(n) and not ip then
local index=findindex(n) 
tbl.ip=index
end
n,fun=navigate(n) -- fun , wenn nicht = nil ist eine Hinweisfunktion,
                  -- die letztlich in einer TimedMessage landet.
if n > N then return end
if tap1 then sposTo(navi().prim) end
local y=Y(n)
tbl.p=n; if fun then tbl.hfun=fun end
y=(HEIGHT-1)/2+y - wCell/2
local exe = (ani and gr.isOpen) and scrollGridAni or scrollGridTo
exe(y,tbl)
if tbl.ip then gi(tbl) end
end

--[[
A mix of gg and gi
--]]
function gm(tbl) -- tbl muss die Form {p=...,ani=true,ip=...} haben
local p=tbl.p    -- wobei ... Zahlen andeuten.
local ip=tbl.ip
local ani=tbl.ani
if not p and ip  and 1 <=ip and ip <= countprimes then p=pr(ip)end
if not ip and p and 1 <= p and p <= N then ip=findindex(p) end
if p then local tblg={p=p,ip=ip,ani=tbl.ani,tdelta=tbl.tdelta and tbl.tdelta or 10.0} gg(tblg) end
if ip then  local tbli={ip=ip,ani=tbl.ani,tdelta=tbl.tdelta and table.tdelta or 10.0} gi(tbli) end
end

--[[
Findet den index in pt zu einer gegebenen Primzahl n.
Gibt nil zurück, wenn nicht gefunden.
--]]
function findindex(n)
local found 
for i=1,countprimes do if pr(i)==n then found=i break end end  
return found
end

--[[
Zur Auffüllung angebrochener Gitterzeilen mit Zahlen.
Entdeckt wird ein solcher Fall interaktiv durch Tippen
auf eine leere Gitterzelle in der letzten (unteren)
Gitterzeile.
--]]
function completeSEto(n)
if N < n  and n <= 9999999 then
    if prim == 1 then
        for i=N+1,n do setm(i,2) end-- zur Ergänzung angebrochener Gitterzeilen
        N=n
        updateTitle()
    elseif fertig then
        setN(n) 
    end
end
end

--[[
Soll die getroffene Zahl in {1,...N} ermitteln; eventuell auch für den 
Divisionsrest R=N%10 für Zahlen in N+1,... N+R ,falls N nicht durch 10 
teilbar ist. Dort sind die Zahlen im Gitter eventuell noch nicht eingetragen.
--]]
function hitGrid(touch)
local nn=0
if 0 <= touch.x and touch.x <= GB then
        local x,y=touch.x,touch.y
        x=math.floor((x-1)/wCell)+1     -- Spalte von links gezählt
        y=math.floor((gr.Y-y)/wCell)    -- Zeile von oben gezählt
        nn = y*10+x
end
return nn
end

--[[
Zeige den Inhalt des Zahlengitters ganz unten.
--]]
function zeigeGridunten()
if gr.isOpen then scrollGridTo(gr.yMax) end
end

--[[
Wird von einer Animation aufgerufen.
--]]
function gridscrollFinish()
sound(SOUND_JUMP, 9979) 
volldurchlauf=false
end

--[[
Ein closure for navigation in inspection mode.
Die erste Rückgabe-Funktion  dieser Funktion transformiert 
die Fingertips ins Gitter, um nach Abschluss des Siebvorgangs 
Primzahlen und ihre Vielfachen visuell zu inspizieren, und so
den Ablauf ndes Siebes nochmal nachträglich nachzuvollziehen. 
Es gibt eine einzige Aufrufstelle in der Gitter-Funktion gg.
Die hier anonyme erste zRückgabe-Funktion heisst dort navigate.
Besonders nützlich ist die Methode eine einmal besuchte 
Gitterzelle nochmals anzutippen, um zur nächsten relevanten 
Zelle zu kommen, wenn der Abstand dazu so groß ist, dass diese
Nächste nicht sichtbar ist.
--]]
function Navigation()
--[[
Returns a function-triple for navigation in results of sieving.
Das Triple heisst - zugewiesen in setup() - navigate,navi,naviText

--]]
local navi={prim=1,ld=1,multi=1}
local navitxt="{ prim = "..tostring(9999999)..", ld = "..tostring(9999)..", multi = "..tostring(9999999).." }"
local fntsize=12
    
--[[ ------------------------------------------------------------------------------------
Die beiden folgenden Funktionen produzieren eine textliche Fehlermeldung 
beim  Versuch über die Siebgröße hinaus zu navigieren, der Versuch wird
allerdings intern unterbunden.
--]]
local function mppgtN() -- bedeutet: multi+prim greater than N
local p,multi=navi.prim,navi.multi
local txt=table.concat{multi,"+",p," > ",N} return txt 
end
    
local function ppgtN() -- bedeutet: prim*prim grater than N
local p=navi.prim
local txt=table.concat{p,"*",p," > ",N} return txt
end
------------------------------------------------------------------------------------------   
     
pushStyle()
font("Courier"); fontSize(fntsize)
nw,nh=textSize(navitxt)
popStyle()
return       -- Die Returnwerte kommen noch, Es sind 3 Funktionen. 
function (n) -- 1. Rückgabefunktion navigate: Navigiert mit Hilfe von navi
--[[
Die hier anonyme Funktion heisst im Globalen navigate. Sie arbeitet wie ein iterator, 
der durch Primzahlen und ihre Vielfachen iteriert .Sein status ist die table navi.
Die Vielfachen werden wie im Siebalgorithmus behandelt: Nachfolger eine Primzahl ist
deren Quadrat.
Das Navigieren wird durch Fingertips ins Gitter oder in die Primzahltabelle ausgelöst.
Ausgehend von einer Primzahl p navigiert die Funktion - bei wiederholtem Antippen eines
bereits erreichten Navigationsziels zu Vielfachen von p. Falls man etwas anderes antippt,
stellt sich die Funktion auf den kleinsten Teiler einer angetippten zusammengesetzten Zahl
als neue Primzahl ein, oder auch auf eine andere angetippte Primzahl.
Falls es zu einem Vielfachen von p kein weiteres Vielfache <= N gibt und man tippt wieder
darauf, gibt es einen Hinweis darauf, dass es nicht mehr weiter geht. Ebenso wird verfahren,
wenn p*p > N ist, denn dann gibt es überhaupt keine "Vielfachen <= N" von p, und es gibt 
einen anderen Hiweis. Die beiden Hinweisfunktionen mppgtN,ppgtN sind interessant. Es
sind locale Functionen relativ zu Navigation() - insbesondere nichtglobal. Trotzdem gelingt
es diese Funktionen von aussen aufzurufen. Sie werden von der vorliegenden anonymen Funktion
über die Kette ---> gg ---> ScrollGridAni ---> gTM:Start ---> gFunc weitergereicht, um zuletzt
im Rahmen des TimedMessage-Objekts gTM einen zeitlich begrenzten Hinweis zu zeigen.
Dabei wirkt zwischen ScrollGridAni und gTM:Start noch das Animations-System tween.
--]]
if isPrim(n) 
    then
        local prim,ld,multi=navi.prim,navi.ld,navi.multi
        navi.prim=n; navi.ld=1; navi.multi=1 
        if n==prim and ld==1 and multi==1 then
                local fun=nil
                if n*n <= N then navi.ld=n navi.multi=n*n  else fun=ppgtN end
                return n*n <= N and navi.multi or navi.prim,fun
            else
                navi.prim=n; navi.ld=1; navi.multi=1
                return navi.prim
            end
     else 
        if navi.prim==1 then navi.prim,navi.ld=SE[n],SE[n]  navi.multi=n return navi.multi 
        elseif n%navi.prim == 0 then
            local fun=nil
            if navi.multi == n then
                local nn=n+navi.prim
                if nn <= N then navi.multi=nn else  fun=mppgtN end
            else
                navi.multi=n
            end
            navi.ld=SE[navi.multi]
            return navi.multi,fun
        else navi.prim,navi.ld=SE[n],SE[n] navi.multi=n 
            return navi.multi
        end
     end
end,
function () return navi end,    -- 2. Rückgabefunktion navi: Gibt die gekapselt table navi zurück.
function ()                     -- 3. Rückgabefunktion naviText: Gibt eine Textdarstellung des Inhalts von navi zurück.
local txt=table.concat{"{ prim = ",navi.prim,", ld = ",navi.ld,", multi = ",navi.multi," }"}
return txt,nw,nh,fntsize  -- außer txt auch Breite,Höhe der textbox und benutzten fontSize zurück geben.
end
end

