--# Info
-- Rechter Info-Streifen mit Liste der aktuell gefundenen Primzahlen.

--[[
    Bedienmöglichkeiten in der oberen Livezeile hinzugefügt:
    1. start/stop
    2. Umschalten Animation
    3. Umschalten zwillinge
    4. Umschalten Inspektionsmodus
--]]

--[[
Anhängen einer neuen gefundenen Primzahl n an die Tabelle pt.
In der Tabelle werden die Primzahlen und eine Kennzeichnung (gesetztes höchstes bit)
für Primzahlzwillinge gespeichert. Die Tabelle pt ist ( seit 17.04.2018 ) eine 
eindimensionale Tabelle der Form: {p1,p2,...,plast} wobei die p1,p2,... die fortlaufenden
Primzahlen sind.
Eine Primzahl kann zu einem fortlaufenden Eintrag mit der Nummer i durch pt[i] 
referenziert werden (i=1,...,countprimes). 

Die Eigenschaft "Mitglied eines Primzahlzwillings" wird  ( seit 17.04.2018 ) 
im höchsten bit von pt[i] gespeichert:
Gesetztes bit bedeutet Primzahlzwilling. 
Nicht gesetztes bit bedeutet Nicht-Primzahlzwilling.
Mit dieser Behandlung der Primzahlzwillinge geht einher, dass das Auslesen einer Primzahl
aus der Tabelle pt am index i jetzt durch den Ausduck 0x7FFFFFFF&pt[i] erfolgen muss, den man
einheitlichkeitshalber immer anwenden sollte - unabhangig davon ob am index i ein Primzahlzwilling 
gespeichert ist oder nicht. Die Funktion pr(i): i=1,...,countprimes leistet das.

Die farbliche Darstellung der Primzahlzwillinge wird erst duch den Schalter "zwillinge"
geleistet: Schalterstellung rechts. 
Die Behandlung der Primzahlzwillinge hat nichts mit dem eigentlichen Siebvorgang zu tun
sondern ist eine Zusatzleistung.
24.04.2018 - Die Information ob eine Primzahl Zwilling ist wird in appendPrim(n) auch 
in die table SE übertragen und dort im höchsten bit von SE[n] mit Wert 1 gespeichert, also
an gleiche Bitposition wie in pt[c-1],pt[c] -vgl. die Stelle im Code von appendPrim(...).
--]]
function appendPrime(n)
local hbit=0x8000000000000000   -- beruht auf der Annahme,dass ganze Zahlen 64 bits haben 
                                -- 0x7FFFFFFFFFFFFFFF = 9223372036854775807 = math.maxinteger 
                                -- ist nach der lua-Dokumentation die größte integer-Zahl
                                -- solche Zahlen bei denen das höchste bit gesetzt ist wie bei hbit
                                -- sind dann negative integers.
countprimes = countprimes + 1 
pt[#pt+1]=n -- eine neue Primzahl n ans Ende der Liste anhängen
prim=n
prim_countprimes = tostring(prim).." / "..countprimes -- für einen parameter.watch(...)
local c=#pt
if countprimes > 1 and pr(c)==pr(c-1)+2 then -- Behandlung von Primzahlzwillingen
    local p,q=pr(c),pr(c-1)
    SE[p],SE[q] = (hbit|SE[p]), (hbit|SE[q]) -- auch in SE als Zwillinge kennzeichnen
    twinpairs = twinpairs + 1 
    -- ein gesetztes hbit in pt[c] kennzeichnet Primzahlzwillinge
    pt[c],pt[c-1] = hbit|pt[c], hbit|pt[c-1]
end
    
if ecount==countprimes then
    adjustInfoScrollrange()
    if timekeeping then setTimeResult() end        
end
if (countprimes%5)==1 then adjustInfoScrollrange() end  
    -- Range anpassen,wenn sich die Zeilenzahl der Primzahlliste erhöht hat.      
end

--[[
Textform einer Zeitmessung
--]]
function setTimeResult()
local t=os.clock()
    local tt=t-time
    local prec = N < 770 and 0.0000000001 or 0.000001
    timetext = "time for "..tostring(math.floor(N)).." = "..tostring(tt-tt%prec).." sec"    
end

--[[
Textform einer Primzahl p in der Ausgabeliste.
Führende Leerzeichen zum Erreichen eine einheitlichen
Länge des Ausgabetextes werden erzeugt.
--]]
function pTX(p)
local l=math.floor(math.log10(p))+1 -- Anzahl der Dezimalstellen von p
local ff= N >= 1000000  and 7 or 6
local s=math.max(0,ff-l) -- s führende Leerzeichen  " " erforderlich
-- Test ob die letzte Primzahl vorliegt oder nicht (dann Komma weglassen oder setzen).
local tx=(countprimes==ecount and p==pr(countprimes)) and string.rep(" ",s)..p 
                                                          or string.rep(" ",s)..p..","  
return tx  
end

--[[
Koordinaten einer Primzahl pt[i] in der Ausgabeliste
--]]
function pXY(i)
local x,y = 1,1  
local yy=math.floor((i-1)/5)  
local xx=(i-1)%5 
x,y=GB+wsT+xx*wiT,(yy+1)*hiT    -- wsT für ein führendes Leerzeichen pro Zeile
return x,y
end

--[[
Start/End-Index der Ausgabeliste. Die eigentliche Liste
kann größer sein. Es werden nur die tatsächlich sichtbaren
Listenelemente ausgegeben.
--]]
function seInfo()
local s = ir.Y > ir.yMin and 5*math.ceil((ir.Y-ir.yMin)/hiT)+1 or 1   
local e=5*(math.ceil(ir.yMin/hiT)-1)
e=s+e <= countprimes and s+e or countprimes
return s,e
end

--[[
Liste der bisher gefundenen Primzahlen als Text ausgeben.
Die vertikalen Ausgabepositionen werden noch an der 
obersten Position ir.Y gespiegelt; ir.Y ist auch fürs Scrollen wichtig. 
Die Darstellung arbeitet "Ausgabe/Zugriffs-sparend":
Es wird nur das ausgegeben was sichtbar ist.
Es entsteht eine 5-spaltige Liste von durch Komma getrennten Primzahlen.
--]]
function drawPrimes()
pushStyle()
FONT()
fontSize(fntsize)
textMode(CORNER)
fill(clr(2))
if countprimes > 0 then
    local s,e=seInfo()
    -- Ausgabefunktion ausgewählen nach dem Wert von zwillinge
    local dp = zwillinge and drawptwins or drawp 
    for i=s,e do dp(i) end
end
popStyle()
end

--[[
Ausgabe der Primzahltexte mit farblicher Berücksichtigung der Primzahlzwillinge.
Primzahlzwillinge werden weiss ausgegeben.
Normale Primzahlen (Nichtzwillinge) werden grün ausgegeben.
--]]
function drawptwins(i) 
pushStyle()
fill(isTwinAt(i) and clr(4) or clr(2))  -- weiss oder grün
local x,y=pXY(i)
text(pTX(pr(i)),x,ir.Y - y)   
popStyle()   
end

--[[
Ausgabe der Primzahltexte ohne farbliche Berücksichtigung der Primzahlzwillinge.
--]]
function drawp(i)
local x,y=pXY(i)
text(pTX(pr(i)),x,ir.Y - y)
end

--[[
draw-function for TimedMessage-Objekt iTM
--]]
function iFunc(tbl) 
local i=tbl.ip -- tbl.ip ist index in table pt, tbl.p wird nicht benutzt.
if i < 1 or i > countprimes then return end
pushStyle()
local ti = colortables.act==2 and 1 or 2
FONT(ti)
fontSize(fntsize)
fill(clr(a.bg,ti))
noStroke()
rectMode(CORNER)
local txt=pTX(pr(i))
local x,y=pXY(i)
local w,h=textSize(txt)
rect(x,ir.Y-y,w,h)
if zwillinge then 
    fill(isTwinAt(i) and clr(a.infotwins,ti) or clr(a.infoprim,ti))
else
    fill(clr(a.infoprim,ti))
end
textMode(CORNER)
text(txt,x,ir.Y - y)
popStyle()   
end

--[[
Scrollt - wenn der Scrollrange nicht zu klein ist - vertikal im Infobereich 
derart, dass die n-te Primzahl in der vertikalen Mitte erscheint.
Merkbrücke: gi ist: go in info (to n-the prime)
--]]
function gi(tbl)  -- tbl.ip ist index in die Primzahltabelle pt
local n,ani=tbl.ip,tbl.ani
if 1 <= n and n <= countprimes then
local _,y = pXY(n)    
y = y + (HEIGHT-1)/2
local exe = ani and scrollInfoAni or scrollInfoTo
exe(y,tbl)
end
end

--[[
Findet heraus, welche Zelle in der Primzahlliste getroffen wurde.
--]]
function hitInfo(touch)
if GB < touch.x and touch.x <= BI then
local n=0
local x,y=touch.x,touch.y
    x=math.floor((x-1-GB-wsT)/wiT)+1    -- Spalte von links gezählt
    y=math.floor((ir.Y-y)/hiT)          -- Zeile von oben gezählt
    n = y*5+x
    return n
end   
end

--[[
Zeichnet den blauen Tropfen im Info-Bereich oben,rechts/links.
Die boolean Variable tap1 steuert jetzt (16.04.2018) sowohl im Gitter 
als auch im Info-Bereich ein gleichartiges Verhalten bezüglich Fingertips
Der Wert false führt zur Verwendung von tapGrid(...),tapInfo(...),
der Wert true  führt zur Verwendung von tap1Grid(...), tap1Info(...). 
Letzteres ist der Inspektion-Modus.
--]]
function drawTap1()
pushStyle()
fill(clr(a.multi))
fontSize(fntsize)
textMode(CORNER)
if tap1 then text("💧",BI-2*wsT,yTop-hiT/6) else text("💧",GB,yTop-hiT/6) end
popStyle()
if tap1 then else end
end

--[[
Vertikale Drittelpositionen festlegen die dann für
horizontale Linien im Infobereich genutzt werden,
um eine tipp-sensitive  Zone sichtbar zu machen.
--]]
function defineThirdsLines()
yThirdBottom=HEIGHT/3                  ; yThirdBottom=math.ceil(yThirdBottom/hiT)*hiT
yThirdTop   =HEIGHT-yThirdBottom
yThirdMiddle=(yThirdBottom+yThirdTop)/2; yThirdTop=math.ceil(yThirdTop/hiT)*hiT
end

--[[
Drittellinien rechts neben Info zeichnen.
Sieht man nur, wenn Screenweite groß genug ist,
etwa im iPad-Landscape-Modus. Der Bereich innerhalb dieser
Drittelinien ist eine besonder Bedienfläche, was mittels
drawTip() noch angezeigt wird.
--]]
function drawThirdsLines()
pushStyle()
stroke(clr(a.thirdlines))   
strokeWidth(1) 
line(GB,yTop,BI,yTop)
local yy = yTop-2*hCell
yy =math.ceil(yy/hiT)*hiT
line(GB,yy,BI,yy)
line(GB,yThirdTop,BI,yThirdTop)         -- obere Drittellage
line(GB,yThirdBottom,BI,yThirdBottom)   -- untere Drittellage
line(BI,0,BI,HEIGHT)
line(GB,0,GB,HEIGHT)
popStyle()
end

--[[
Titel des Projekts und Anzahl der gefundenen Primzahlen anzeigen
--]]
function drawTitleandCountPrimes()
pushStyle()
fill(clr(a.infotext))
FONT()
fontSize(fntsize)
textMode(CORNER)
local yMin=HEIGHT-1
local ww,hh=textSize(Title)
local left=GB + (ww > BI-GB and 0 or (BI-GB-ww)/2)
text(Title,left,HEIGHT-1-(hiT+2*hh))
local etxt= ecount and " von "..ecount or ""
local txt=countprimes..etxt.." Primzahlen gefunden"
ww,hh=textSize(txt)
left=GB+(ww > BI-GB and 0 or (BI-GB-ww)/2)
text(txt,left,HEIGHT-1-(hiT+3*hh))
popStyle()  
end

--[[
Beendigung des Siebens durch einen Text ganz unten anzeigen.
--]]
function drawEndmeldung()
pushStyle()
FONT()
fontSize(fntsize)
textMode(CORNER)
fill(clr(a.infotext))
local txt=countprimes.." Primzahlen <= "..math.floor(N).." gefunden"
local ww,hh=textSize(txt)
local left=GB + (ww > BI-GB and 0 or (BI-GB-ww)/2)
local y=hiT*(math.ceil(countprimes/5)+1)
text(txt,left,ir.Y-y)
y = y + hiT
txt="Darunter "..twinpairs.." Zwillingspaare"
ww,hh=textSize(txt)  
left=GB + (ww > BI-GB and 0 or (BI-GB-ww)/2)
text(txt,left,ir.Y-y)
popStyle()   
end

--[[
Das ist enorm wichtig fürs Scrollen im rechten Info-Bereich:
Der InfoScrollrange ir={yR=...,yMin=..., yMax=...} verwaltet:
yR   - Die vertikale Scrollposition, die auch durch Fingerbedieinung bewegt wird.
yMin - Die vertikale Mimimal-Lage von yR
yMax - Die vertikale Maximal-Lage von yR 
       (Liegt oberhalb von HEIGHT, falls überhaupt gescrollt werden muss.)
--]]
function adjustInfoScrollrange()
local y=yTop 
ir.yMin=y; ir.yMax=ir.yMin; ir.Y=ir.yMin
local l=hiT*(2+math.ceil(countprimes/5))   -- needed place (2+ für die beiden Textzeilen ganz unten)
local ll=hiT*(math.floor(ir.yMin/(hiT)))   -- available place
if l > ll  then ir.yMax = ir.yMin+(l-ll) ir.yMax=math.ceil(ir.yMax/hiT)*hiT end 
ir.Y = ir.Y > ir.yMax and ir.yMax or ir.Y
ir.Y = ir.Y < ir.yMin and ir.yMin or ir.Y
ir.isOpen = ir.yMin < ir.yMax and true or false
end

--[[
Vertikales Scrollen mit einem Finger ( vertikal bewegen) im Info-Streifen.
Beim Scrollen wird die vertikale Position ir.Y modifiziert.
Im oberen Bereich über der Primzahlliste wird die horizontale
Bewegung ausgewertet, um die drei boolschen Schalter Animation,
zwillinge  und tap1 zu verändern.
--]]
function scrollInfo(touch)
if GB < touch.x and touch.x < WIDTH then
    if HEIGHT-1-hCell <= touch.y and touch.y <= HEIGHT-1 then   -- Animation ändern
    if touch.x < touch.prevX then Animation= false else Animation = true end 
    elseif yTop <= touch.y and touch.y < HEIGHT-1-2*hiT then     -- zwillinge ändern
            if touch.x  < touch.prevX then Zwillis(false) else Zwillis(true) end
    elseif yTop-2*hCell <= touch.y and touch.y < yTop then
                                -- Inspektionmodus off/on --
            tap1 = touch.x  >= touch.prevX and true or false
    elseif BI< touch.x and touch.x < WIDTH and yThirdBottom <= touch.y and touch.y <= yThirdTop then
            if touch.x  < touch.prevX then timekeeping=false else timekeeping=true end
    elseif touch.y < yTop-2*hCell then ---------------------------------------------------- vertikal scrollen    
        local yR,yMin,yMax=ir.Y,ir.yMin,ir.yMax
        if yMax > yMin then         
            local y=touch.y-touch.prevY
            yR = yR + y
            if yR < yMin then yR=yMin end
            if yR > yMax then yR=yMax end
        end
        ir.Y=yR
    end
end
end

--[[
Tippen - mit einem Finger - in den Infobereich führt ganz nach unten
oder ganz nach oben, oder in der Live-Zeile: start/stop und Animation 
umschalten.
--]]
function tapInfo(touch)
if GB+wsT < touch.x and touch.x < WIDTH then --Infobereich getroffen
    if HEIGHT-1-hCell <= touch.y and touch.y <= HEIGHT-1 
    then -- Live-Zeile getroffen
            --[[ 
            Bedienung im oberen Livestreifen. Es wird unterschieden,
            ob beim Tippen das gelbe Live-Rechteck getroffen wird oder nicht.
            --]]
            local x,wr=lt.spos.x,wCell+15
            local hit = (x-wCell/2 <= touch.x and touch.x <= x+wCell/2) and true or false
            if not running then -- start
                if  hit then allessieben()   else Weiter()  end
            else -- stop
                if hit then  abbruch() else unterbrechung() end
            end
    elseif  touch.y < yThirdBottom then ir.Y=ir.yMax
    elseif touch.y > yThirdTop    then ir.Y=ir.yMin;
    else  
    aniAbort()             
    end
end
end

--[[
Inspektionsmodus bedienen: Durch Antippen eine Zahl
auf beiden Seiten (Gitter/Info) farblich hervorheben
und - falls ausführbar - in die vertikale Mitte rücken.
Man kann auch eine Zahl nach der Aktion nochmal 
antippen, dann wird zur nächsten "Vielfachen" navigiert.
--]]

--[[
Zu tapInfo(...) umleiten, wenn Siebvorgang noch läuft.
--]] 
function tap1Info(touch) 
if ecount~=countprimes then return tapInfo(touch) end 
---------------------------------------------------------
if GB +wsT < touch.x and touch.x <= BI then
    if HEIGHT-1-hCell <= touch.y and touch.y <= HEIGHT-1 then -- Live-Zeile getroffen
        local p,x,wr=navi().prim,touch.x,wiT+24
        local xl,xr=lt.spos.x-wr,lt.spos.x+wr
        local hitleft,hitin,hitright= x < xl,(xl <= x and x <= xr),xr < x
        --[[
        Bei hitleft und hitright wird das Konzept realisiert
        zu einem Vielfachen multi >= p*p zu springen, genau so wie
        beim originalen Siebablauf. Man vergleiche dazu den Kommentar in
        der Funktion streicheVielfache(n). Der Inspektionsmodus soll nichts
        machen, was dem Siebablauf wiederspricht. Insbesodere darf nicht
        zu einem Vielfachen multi gesprungen werden, das nicht mit einem 
        blauen Rahmen gekennzeichnet ist.
        --]]
        if hitleft then 
            if p > 1 then 
                local k=p*p 
                if k > N then k=p end
                gg{p=k,ani=true} 
            end
        elseif hitin then  
            if p > 1 then 
                gg{p=p,ani=true} 
            end
        elseif hitright then 
            if p > 1 then 
                local  lastmulti = p*math.floor(N/p) 
                if lastmulti <= p*p and  p*p > N then lastmulti=p end 
                -- lastmulti=p sieht seltsam aus, ist aber so gewollt.
                gg{p=lastmulti,ani=true}    
            end
        end
    else
        local tblg,tbli={ani=true,tdelta=10.0},{ani=true,tdelta=10.0}
        local n=hitInfo(touch)
        if n < 1 or n > countprimes then return end
        local p=pr(n)
        tbli.ip=n
        tblg.p=p
        -- vorherige Anzeige von TimedMessage-Objekten abbrechen.
        gTM.running,iTM.running=false,false 
        gi(tbli) -- Aktion in der Primzahlliste
        gg(tblg) -- Aktion im Gitter
    end 
end
end

--[[
Animiertes Scrollen im Inspektionmodus
--]]
function scrollInfoAni(y,tbl) -- y  i,t:ist Scrollposition,i index in pt, t ist eine Zeitdauer
y=y < ir.yMin and ir.yMin or y
y=y > ir.yMax and ir.yMax or y
if tbl then 
local  id=tween(1.0,ir,{Y=y},tween.easing.linear,iTM.Start,iTM,tbl)
tween.play(id)
end
end

--[[
Animiertes Scrollen des Inhalt des Info-Streifens nach ganz unten.
--]]
function scrollInfounten()
scrollInfoAniTo(ir.yMax)
end

--[[
Animiertes Scrollen zu einer bestimmten Position.
--]]
function scrollInfoAniTo(y)
local  id=tween(1.0,ir,{Y=y},tween.easing.linear,playsound,{SOUND_JUMP,9979})
tween.play(id)  
end

function playsound(s)
if s then sound(unpack(s)) end
end

--[[
Gezieltes programmiertes Scrollen - ohne Animation - zu einer angegebenen 
vertikalen Position y. fun ist iTM.Start
--]]
function scrollInfoTo(y,fun,arg,tbl)
if ir.isOpen then
y=y < ir.yMin and ir.yMin or y
y=y > ir.yMax and ir.yMax or y
ir.Y=y
end
if fun and arg and tbl.tdelta and tbl.ip then
fun(arg,tbl)        
end
end


--[[
Inhalt des Info-Streifens ganz unten anzeigen
--]]
function zeigeInfounten()
if ir.isOpen then ir.Y=ir.yMax else ir.Y=ir.yMin end
end
