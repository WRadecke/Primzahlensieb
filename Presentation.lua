--# Presentation

--[[
Behandlung von Fingereingaben im Hauptfenster.
Hier werden die Fingereingaben nur verteilt.
--]]
function touched(touch)
    if touch.state == BEGAN then
    end
    --es wird fast nur auf vertikale Bewegungen reagiert
    if touch.state == MOVING then 
        scrollGrid(touch) -- Finger bewegen im Gitter
        scrollInfo(touch) -- Finger bewegen im rechten Info-Bereich ganz oben auch horizontal
    end
    if touch.state == ENDED then 
        if touch.tapCount==1 then -- Reaktion auf ein "tap"="tippen"
            if splashRunning() then  splashEnd() return end -- "Spirale" beenden.
            local tapfun  = tap1 and tap1Grid or tapGrid
            tapfun(touch)
            local tapIfun = tap1 and tap1Info or tapInfo
            tapIfun(touch)
        end
    end  
end

--[[
Strukturen zur Unterstützung von (bisher) 2 Farbschemata für das Hauptfenster ----------
--]]
function defineColorTables()
colortables=
{
{ -- Primärtabelle - dunkles Design
  color(255,0,0)            -- [1] für Nichtprimzahlen
 ,color(0,255,0)            -- [2] für Primzahlen
 ,color(255,255,0)          -- [3] für noch nicht bearbeitete Zahlen
 ,color(255,255,255)        -- [4] für Primzahlzwillinge
 ,color(255,255,0)          -- [5] für das animierte Rechteck
 ,color(0, 213, 246, 255)   -- [6] für Kennzeichnung der Vielfachen
 ,color(255,255,255)        -- [7] für Gitterlinien
 ,color(40, 40, 50)         -- [8] background
 ,color(0,255,0)            -- [9] für LiveLine
 ,color(255, 210, 0, 255)   -- [10] für Liverect fill
 ,color(0,255,0)            -- [11] für Liverectborder
 ,color(255,255,255)        -- [12] für Live-Ellipse fill
 ,color(0,0,0)              -- [13] für Live-Ellipse Rand
 ,color(0,0,0)              -- [14] für Live-Primzahl-Anzeige
 ,color(0,255,0)            -- [15] für Primzahlen im Info-Bereich
 ,color(255,255,255)        -- [16] für Primzahlzwillinge im Info-Bereich
 ,color(255,255,255)        -- [17] für Texte im Infobereich
 ,color(255,0,0)            -- [18] für Nichtprimzahlen beim Zurückschalten von NichtPrimzahlen_Tarnen
 ,color(255,255,255)        -- [19] für Drittel-Linien
 ,fnt="Courier"
}
,
{ -- Sekundartabelle: helles Design ,zufriedenstellend (27.03.2018)
  color(255,0,0)            -- [1] für Nichtprimzahlen
 ,color(0,255,0)            -- [2] für Primzahlen 
 ,color(255, 210, 0, 255)   -- [3] für noch nicht bearbeitete Zahlen
 ,color(255,255,255)        -- [4] für Primzahlzwillinge
 ,color(255,255,0)          -- [5] für das animierte Rechteck
 ,color(0, 213, 246, 255)   -- [6] für Kennzeichnung der Vielfachen
 ,color(255, 210, 0, 255)   -- [7] für Gitterlinien
 ,color(170,170,170)        -- [8] background color(255, 210, 0, 255)
 ,color(0,255,0)            -- [9] für LiveLine
 ,color(255, 210, 0, 255)   -- [10] für Liverect fill
 ,color(0,255,0)            -- [11] für Liverectborder
 ,color(255,255,255)        -- [12] für Live-Ellipse fill
 ,color(0,0,0)              -- [13] für Live-Ellipse Rand
 ,color(0,0,0)              -- [14] für Live-Primzahl-Anzeige
 ,color(0,110,0)            -- [15] für Primzahlen im Info-Bereich
 ,color(255,255,255)        -- [16] für Primzahlzwillinge im Info-Bereich
 ,color(255,255,255)        -- [17] für Texte im Infobereich
 ,color(255,0,0)            -- [18] für Nichtprimzahlen beim Zurückschalten von NichtPrimzahlen_Tarnen
 ,color(0,0,0)              -- [19] für Drittel-Linien
 ,fnt="Courier-Bold"
}
,act=1                      -- index in die aktuelle colortable
}   
end

--[[
Tabelle mit Paaren (Schlüssel,ganze Zahl) für "symbolische" Zugriffe in die colortables.
Die ersten vier colorwerte werden nur "nicht-symbolisch" behandelt,
das bedeutet nur über indizes in {1,2,3,4}.
--]]
a=
{
  anirect=           5
 ,multi=             6
 ,gridlines=         7
 ,bg=                8
 ,liveline=          9
 ,liverect=         10
 ,liverectborder=   11
 ,liveelli=         12
 ,liveelliborder=   13
 ,liveprim=         14
 ,infoprim=         15
 ,infotwins=        16
 ,infotext=         17
 ,nonprimes=        18 -- Reserve beim Zurückschalten von NichtPrimzahlen_Tarnen
 ,thirdlines=       19
}

--[[
Setzen des Farbschemas
--]]
function setFS(val)
Farbschema=val
colortables.act=Farbschema and 2 or 1
-- notwendige Ergänzung (19.04.2018)
local c = NichtPrimzahlen_Tarnen and clr(a.bg) or clr(a.nonprimes)
farbe(1,c)
end

--[[
Lesende Zugriffs-Funktion auf Farben in einer der Colortables
--]]
function clr(i,ti) -- arguments are index,tableindex
i=i or 1                    -- default index ist 1 (wird bisher nicht genutzt)
ti= ti or colortables.act   -- default tableindex ist colortables.act
return colortables[ti][i]
end

--[[
Auswählen eines Font , der in den beiden colortables definiert ist.
--]]
function FONT(ti)
ti=ti or colortables.act -- default table ist die aktuelle colortable
font(colortables[ti].fnt)
end
-- Ende Farbschemafunktionen ---------------------------------------------------------

--[[
Kennzeichnung von Primzahlzwillingen anpassen.
Die Anpassung wird hier nur für Das Zahlengitter realisiert,
indem der farbindex im Siebzustand SE[p] für jede der zu
als Primzahl erkannten Zahlen p eingestellt wird. Ein Zwillingspaar
kann erst erkant werden, wenn der größere der beiden Zwillinge
erkannt wurde. Diese Erkennung geschieht in der Funktion appendPrimes().
Dauert etwa 0.1 Sekunden bei N=9999999.
Die Anpassung für die rechte Primzahlliste wird innerhalb der
Funktion drawPrimes() geleistet.
--]]
function Zwillis(val)
zwillinge=val
-- colorindex-Funktion anpassen
CI = zwillinge and clrindextwin or clrindexnorm
end

function updateTitle()
Title="Sieb des Eratosthenes("..math.floor(N)..")"   
end

--[[
Setzen der Position des "fliegenden" Rechtecks zur
Position der Gitterzelle der Zahl i.
--]]
function sposTo(i)
 spos.x,spos.y = X(i),Y(i)
end

--[[
Setzen der Endposition des "fliegenden" Rechtecks zur
Position der Gitterzelle der Zahl i. 
Die Endposition spielt nur bei Animationen gesteuert
durch tween(...) eine Rolle und wird nicht visualisiert.
--]]
function eposTo(i)
epos.x,epos.y = X(i),Y(i)   
end

--[[
Kennzeichnung der aktuellen Bearbeitungsposition im Gitter
durch einen fetten gelben "fliegenden" Rahmen.
Zu Anfang - wenn noch nicht gesiebt wird - steht der Rahmen auf der
Position der Nichtprimzahl 1. 
Danach bewegt sich der  Rahmen bei aktiver Animation von einer zur nächsten 
Bearbeitungsposition daher das Adjektiv "fliegend":
1. Beim Suchen der nächsten Primzahl von der aktuellen p zur nächsten.
2. Beim Streichen der Vielfachen von p von einem Vielfachen zum nächsten.

Da spos ein globales Objekt ist, kann es ständig innerhalb von draw()
angezeigt werden.

3.Falls Animation nicht aktiv ist springt der Rahmen von Primzahl
  zur nächsten, was man aber nur im Einzelschritt-Verfahren sieht.
4.Am Ende des Siebens - animiert oder nicht - bleibt der Rahmen auf der
  Position derzuletzt gefundenen Primzahl stehen
--]]
function drawspos()
local yy = gr.Y-spos.y
if  yy < 0 or yy >= HEIGHT  then return end
pushStyle()
rectMode(CORNER)
noFill()
stroke(clr(a.anirect))
strokeWidth(4)
rect(spos.x,gr.Y-spos.y,wCell,wCell)
popStyle()  
end

--[[
Setzt eine der Farben unter den ersten 4 Elementen der aktuellen Colortable.
Schreibender Zugriff. Wird nur benötigt für den Fall NichPriemzahlen_Loeschen,
und ausschliesslich für den Farbindex 1 in der aktuellen colortable.
--]]
function farbe(index,c)
local act = math.floor(colortables.act)
if 1 <= index and index <= 4 then colortables[act][index]=c end
end

--[[
Löschfarbe wechseln entsprechend der Schiebeschalterstellung von "NichtPrimzahlen_Tarnen"
--]]
function tarnenChanged(v)
NichtPrimzahlen_Tarnen=v
local c = NichtPrimzahlen_Tarnen and clr(a.bg) or clr(a.nonprimes)
farbe(1,c)
--[[
Die genaue Aktion für die aktuelle colortable ( hier mit ct bezeichnet) ist folgende:
    
1. Falls NichtPrimzahlen_Tarnen == true,  dann        ct[a.bg] ---> ct[1] Untergrundfarbe setzen
2. Falls NichtPrimzahlen_Tarnen == false, dann ct[a.nonprimes] ---> ct[1] Spezielle Farbe setzen
    
Es wird immer nur ct[1] verändert; ct[a.nonprimes] und ct[a.bg] bleiben unverändert.
Im 1. Fall werden im Gitter die Nichtprimzahlen mit der Farbe des Untergrunds eingezeichnet.
      Eine solche Zahl ist im Gitter nicht sichtbar.
Im 2. Fall wird eine sichtbare Farbe gesetzt.
--]]    
end

--[[
Umrahmen der Vielfachen im Gitter hellblau.
Das hat keine algorithmische Bedeutung und dient 
ausschliesslich dem Verständnis des Nutzers.
--]]
function kennzeichneVielfache(p)
k=p*p
if k<=N then
    pushStyle()
    noFill()
    strokeWidth(3)
    stroke(clr(a.multi))
    rectMode(CORNER)
    s,e=seGrid()
    k = s <= k and k or math.ceil(s/p)*p
    for i=k,e,p do rect(X(i)+1,gr.Y-Y(i)+1,wCell-2,wCell-2)  end
    popStyle()
end
end

--[[
Textausgabe vom Ergebnis einer Zeitmessung.
Gemessen wird die Laufzeit des Siebvorgangs.
--]]
function drawTimeText()
if timekeeping and WIDTH > BI then
pushStyle()
FONT()
fill(clr(a.infotext))
textMode(CENTER)
fontSize(fntsize)
text(timetext,(BI+WIDTH)/2,HEIGHT-1-hCell/2)
popStyle()        
end
end

--[[
Ergebnis eines WOLFRAM-Tests ausgeben.
vgl. testWolfram(...)
--]]
function drawTestText()
if WIDTH <= BI or testtext=="" then return end  
pushStyle()
FONT()
fill(clr(a.infotext))
textMode(CENTER)
fontSize(fntsize)
text(testtext,(BI+WIDTH)/2,HEIGHT-1-hCell-hCell/2)
popStyle() 
end

function drawTip()
pushStyle()
stroke(clr(a.liveline))
strokeWidth(5)
-- Pfeil nach links -----------------------
line(BI,yThirdMiddle, BI+50,yThirdMiddle)
line(BI,yThirdMiddle,BI+20,yThirdMiddle+6)
line(BI,yThirdMiddle,BI+20,yThirdMiddle-6)
--Text-------------------------------------
textMode(CENTER)
textWrapWidth(200)
FONT()
fontSize(18)
fill(clr(a.infotext))
tipText= [[Tippe hier links, um eine Animation zu beschleunigen. 
Es wird eine unanimierte Zwischenphase eingelegt.]]

-- Rahmen um Text --------------------------
local wtip,htip = textSize(tipText)
local xcenter,ycenter=BI+50+wtip/2+10,yThirdMiddle
text(tipText,xcenter,ycenter)
rectMode(RADIUS)
noFill()
strokeWidth(2)
rect(xcenter,ycenter,wtip/2+10,math.ceil(htip/2)+10)
local y=math.ceil(htip/2)+10
local xl,yl,xr,yr=xcenter-(wtip/2+10),ycenter+y,xcenter+(wtip/2+10),ycenter+y
drawTK(xl,yl,xr,yr)
yl,yr=ycenter-y,ycenter-y
if tap1 then drawNavi(xl,yl,xr,yr) end
fontSize(fntsize)
fill(clr(a.liveline))
text("-",GB+strokeWidth(),yThirdMiddle)
text("-",BI-wsT,yThirdMiddle)
popStyle()
end

--[[
Zeichnet eine Textdarstellung des aktuellen Inhalts von navi
--]]
function drawNavi(xl,yl,xr,yr)
pushStyle()  
local txt,nw,nh,fntsize=naviText()
FONT()
fontSize(fntsize)
fill(clr(a.liveline))
textWrapWidth(0)
textMode(CENTER)
text(txt,(xr+xl)/2,yl-hiT/2)   
popStyle() 
end
--[[
Über dem "Tiprechteck":
Blauen "Tropfen" links/rechts positionieren um
anzuzeigen dass Zeitmessung off/on ist
--]]
function drawTK(xl,yl,xr,yr)
pushStyle()
fill(clr(a.multi))
fontSize(fntsize)
textMode(CORNER)if timekeeping then text("💧",xr-2*wsT,yr)else text("💧",xl,yl) end
textMode(CENTER)
fill(clr(a.infotext))
text("-off timekeeping on-",(xr+xl)/2,yl+hiT/2)
popStyle()
end

--[[
Generiert die unteren Texte in InfoExt-Bereich
--]]
function drawNaviText(tbl)
pushStyle()
fontSize(18)  
FONT()  
fill(clr(a.infotext))
textMode(CENTER)
local factors,decs,txt={},{},{} 
local txt1,txt2="",""
if WIDTH > BI then  
if tbl.prim > 1 and tbl.ld==1 and tbl.multi==1 then 
    txt1=tostring(tbl.prim).." ist "..findindex(tbl.prim)..". Primzahl"
    text(txt1,(BI+WIDTH)/2,hCell/2)
    return
end
if tbl.prim <= 1 or tbl.ld <= 1 or tbl.multi <= 1 then return end        
factors[1],factors[2] = tbl.ld,math.floor(tbl.multi/tbl.ld)     
if tbl.prim ~= tbl.ld then 
factors[3],factors[4] = tbl.prim,math.floor(tbl.multi/tbl.prim)
end
        
local l,s = 0,0
-- Anzahl der Dezimalstellen der Faktoren und deren Maximum l bestimmen
for i=1,#factors do decs[i] = 1 + math.floor(math.log10(factors[i])) end
for i=1,#decs do  if decs[i] > l then l=decs[i] end end 
-- Texte bis zur maximalen Stellenzahl mit führenden Leerzeichen auffüllen.
for i=1,#factors do s=math.floor(l-decs[i]); txt[i] = string.rep(" ",s)..factors[i]  end
txt1=tostring(tbl.multi).." = "..txt[1].." * "..txt[2] 
if #factors==4 then txt2=tostring(tbl.multi).." = "..txt[3].." * "..txt[4] end
-- Falls beide Texte erscheinen, sind die Produkte passend übereinander ausgerichtet.
if txt1 ~= "" then text(txt1,(BI+WIDTH)/2,hCell/2) end
if txt2 ~= "" then text(txt2,(BI+WIDTH)/2,hCell+hCell/2) end
popStyle()
end
end


--[[
Ein closure für die Durchführung des Wolframtest.
Diese Funktion gibt eine anonyme function (N,last) zurück.
Diese anonyme Funktion hat Zugriff auf die localen Objekte 
von getTailCompare() insbesondere auf die 6 dort kodierten 
Primzahltabellen Das ist eine nützliche lua-Eigenschaft.
Die Funktion getTailCompare wird einmalig in setup() aufgerufen.
der Aufruf dort lautet testWolfram=getTailCompare(). Das Objekt
testWolfram ist dann eine Funktion. Am Ende eines Siebvorgangs 
erfolgt dann ein Aufruf der Form testWolfram(), durch den dann ein 
Wolframtest ausgeführt wird.
--]]
function getTailCompare() 
--[[
Die sechs folgenden Primzahltabellen stammen aus der WOLFRAM CLOUD. 
Es sind jeweils die letzten 100 Primzahlen der Siebvorgänge für die Fälle 
N=1000, N=99999, N=333333, N=999999, N=99999, N=9999999. 
Im 1. Fall N=1000 sind es die vollen 168 Primzahlen. Durch einen Aufruf der
unten kodierten anonymen function (N,last) wird zumindest teilweise getestet,
ob der hier ablaufend Siebvorgang identische Ergebnisse liefert, wie der 
Primzahl-Generator aus der WOLFRAM CLOUD. 
Es wird sozusagen eine zweite Meinung über die Primzahlsuche eingeholt.
Der Befehl für die WOLFRAM CLOUD für unseren Fall N=1000 lautet zum Beispiel:
                    Table[Prime[n],{n,168-99,168}]
Das bedeutet: Suche alle Primzahlen bis zur 168-zigsten und gib nur die letzten 100 aus.

Falls man nur den Befehl Prime[168] eingibt, erhält man 997:    
In[1] = Prime[168]
Out[1]= 997
--]]
local aw=
{ -- Schlüsseltabelle zum Suchen einer Vergleichstabelle
{N=1000,last=997},{N=9999,last=9973},{N=333333,last=333331},
{N=99999,last=99991},{N=999999,last=999983},{N=9999999,last=9999991}
}
    
local wolfram =
{   
{       -- N=1000; Table[Prime[n],{n,1,168}]
2,3,5,7,11,13,17,19,23,29,31,37,41,43,47,53,59,61,67,71,73,79,83,89,97,101,103,107,109,113,127,
131,137,139,149,151,157,163,167,173,179,181,191,193,197,199,211,223,227,229,233,239,241,251,257,263,
269,271,277,281,283,293,307,311,313,317,331,337,347,349,353,359,367,373,379,383,389,397,401,409,419,
421,431,433,439,443,449,457,461,463,467,479,487,491,499,503,509,521,523,541,547,557,563,569,571,577,
587,593,599,601,607,613,617,619,631,641,643,647,653,659,661,673,677,683,691,701,709,719,727,733,739,
743,751,757,761,769,773,787,797,809,811,821,823,827,829,839,853,857,859,863,877,881,883,887,907,911,
919,929,937,941,947,953,967,971,977,983,991,997
}
,
{       -- N=9999; Table[Prime[n],{n,1229-99,1229}]
9109,9127,9133,9137,9151,9157,9161,9173,9181,9187,9199,9203,9209,9221,9227,9239,9241,9257,9277,
9281,9283,9293,9311,9319,9323,9337,9341,9343,9349,9371,9377,9391,9397,9403,9413,9419,9421,9431,
9433,9437,9439,9461,9463,9467,9473,9479,9491,9497,9511,9521,9533,9539,9547,9551,9587,9601,9613,
9619,9623,9629,9631,9643,9649,9661,9677,9679,9689,9697,9719,9721,9733,9739,9743,9749,9767,9769,
9781,9787,9791,9803,9811,9817,9829,9833,9839,9851,9857,9859,9871,9883,9887,9901,9907,9923,9929,
9931,9941,9949,9967,9973
}
,
{       -- N=333333;  Table[Prime[n],{n,28665-99,28665}]
331999,332009,332011,332039,332053,332069,332081,332099,332113,332117,332147,332159,332161,332179,
332183,332191,332201,332203,332207,332219,332221,332251,332263,332273,332287,332303,332309,332317,
332393,332399,332411,332417,332441,332447,332461,332467,332471,332473,332477,332489,332509,332513,
332561,332567,332569,332573,332611,332617,332623,332641,332687,332699,332711,332729,332743,332749,
332767,332779,332791,332803,332837,332851,332873,332881,332887,332903,332921,332933,332947,332951,
332987,332989,332993,333019,333023,333029,333031,333041,333049,333071,333097,333101,333103,333107,
333131,333139,333161,333187,333197,333209,333227,333233,333253,333269,333271,333283,333287,333299,
333323,333331
}
,   
{       -- N=99999; Table[Prime[n],{n,9592-99,9592}]
98897,98899,98909,98911,98927,98929,98939,98947,98953,98963,98981,98993,98999,99013,99017,
99023,99041,99053,99079,99083,99089,99103,99109,99119,99131,99133,99137,99139,99149,99173,
99181,99191,99223,99233,99241,99251,99257,99259,99277,99289,99317,99347,99349,99367,99371,
99377,99391,99397,99401,99409,99431,99439,99469,99487,99497,99523,99527,99529,99551,99559,
99563,99571,99577,99581,99607,99611,99623,99643,99661,99667,99679,99689,99707,99709,99713,
99719,99721,99733,99761,99767,99787,99793,99809,99817,99823,99829,99833,99839,99859,99871,
99877,99881,99901,99907,99923,99929,99961,99971,99989,99991
}  
,
{       -- N=999999; Table[Prime[n],{n,78498-99,78498}]
998551,998561,998617,998623,998629,998633,998651,998653,998681,998687,998689,998717,998737,998743,
998749,998759,998779,998813,998819,998831,998839,998843,998857,998861,998897,998909,998917,998927,
998941,998947,998951,998957,998969,998983,998989,999007,999023,999029,999043,999049,999067,999083,
999091,999101,999133,999149,999169,999181,999199,999217,999221,999233,999239,999269,999287,999307,
999329,999331,999359,999371,999377,999389,999431,999433,999437,999451,999491,999499,999521,999529,
999541,999553,999563,999599,999611,999613,999623,999631,999653,999667,999671,999683,999721,999727,
999749,999763,999769,999773,999809,999853,999863,999883,999907,999917,999931,999953,999959,999961,
999979,999983
}
,
{       -- N=9999999; Table[Prime[n],{n,664579-99,664579}]
9998279,9998281,9998309,9998321,9998323,9998333,9998377,9998381,9998393,9998413,9998423,9998441,
9998447,9998459,9998479,9998539,9998543,9998557,9998561,9998581,9998587,9998603,9998623,9998633,
9998641,9998689,9998699,9998701,9998719,9998741,9998743,9998749,9998753,9998777,9998797,9998801,
9998809,9998851,9998861,9998867,9998887,9998893,9998903,9998929,9998969,9998971,9998977,9999047,   9999049,9999053,9999071,9999083,9999161,9999163,9999167,9999193,9999217,9999221,9999233,9999271,
9999277,9999289,9999299,9999317,9999337,9999347,9999397,9999401,9999419,9999433,9999463,9999469,
9999481,9999511,9999533,9999593,9999601,9999637,9999653,9999659,9999667,9999677,9999713,9999739,
9999749,9999761,9999823,9999863,9999877,9999883,9999889,9999901,9999907,9999929,9999931,9999937,
9999943,9999971,9999973,9999991
}
}
--------------------------------------------------------------------------------------------------------
-- Die folgende anonyme Funktion führt den Wolframtest wirklich aus, allerdings nicht hier , denn sie
-- ist hier nur der Wert den getTailCompare()  zurück gibt.
return function (N,last) -- N sollte die aktuelle Siebgröße sein; last die letzte gefundene Primzahl.
    -- Gibt seit 19.04.2018 keinen Returnwert zurück.
    -- Setzt stattdessen den resultierenden Testtext in der globalen Variablen testtext.
    local ptbl,l=nil,0
    -- Vergleichstabelle mit Primärschlüssel suchen N ist aktuelle Siebgröße
    for i=1,#aw do 
    if aw[i].N==N then ptbl=wolfram[i] ; l = #ptbl break end 
    end
    if not ptbl then
    -- Vergleichstabelle mit Sekundärschlüssel suchen
    for i=1,#aw do  
    if aw[i].last==last then ptbl=wolfram[i] ; l = #ptbl break end 
    end
    end
    if ptbl then   -- passende wolfram-table gefunden
        local f = 0
        local start=#pt-#ptbl+1
        for i=start,#pt 
        do  -- compare entries in wolfram-table ptbl with last entries in our primetable pt
            if ptbl[i-start+1] ~= pr(i)
            then 
            testtext="Fehler "..tostring(i).." , "..tostring(ptbl[f-start+1]).." , "..tostring(pr(i))
            return
            end 
        end
        testtext="Letzten "..l.." von "..tostring(#pt).." OK" return           
    else 
        testtext="Keine Vergleichstabelle gefunden" return 
    end
    end,
    function (i) return wolfram[i] end -- gibt eine der tables zurück
end

TimedMessage=class() -- Nutzung im Inspektionsmodus
--[[
Zeigt eine Textmitteilung tdelta Sekunden lang.
Die Nutzung erfolgt hier durch zwei Objekte gTM,iTM
der Klasse, die zuständig sind für das Gitter bzw. die
Primzahltabelle. Die Textmitteilung besteht hier in der
farblich auffälligen Darstellung bereits vorhandener Zahlen
im Gitter bzw. der sichtbaren Primzahltabelle, sowie von 
Zusatztexten in deren Nähe. Der Nutzer fordert eine solche 
Darstellung an indem er in das Gitter bzw. rechts in die 
sichtbare Primzahltabelle tippt.
Vorausgesetzt wird, dass er den kleinen blauen "Tropfen" rechts
im Titelbereich der Primzahlliste nach rechts bewegt hat.
Der so aktivierte Modus heisst Inspektions-Modus. Eine Tippaktion
im Inspektionsmodus ist verbunden mit dem animierten Scrollen der
betreffenden Elemente in die Vertikale Mitte.
--]]
-- wird durch den Konstruktor aufgerufen (kodiert in setup()).
function TimedMessage:init(func,tstart,tend,tdelta) 
self.drawfunc=func
self.i = 0 -- index of content to draw
self.ip=nil
self.tstart=tstart
self.tend=tend
self.tdelta=tdelta
self.running=false
end

--[[
Start des Runningmodus.
Die Darstellung in farblich auffälliger Form
ist auf die Zeitdauer tdelta beschränkt.
i,ip spezifizieren die zu behandelnden Elemente.
--]]
function TimedMessage:Start(tbl) -- i,tdelta,ip
self.i=tbl.p 
self.ip=tbl.ip
self.hfun=tbl.hfun
self.tdelta = tbl.tdelta and tbl.tdelta or self.tdelta
self.tstart=os.clock()
self.tend=self.tstart+(tbl.tdelta and tbl.tdelta or self.tdelta)
self.running=true   
end

--[[
Diese Funktion muss während des drawings ständig aufgerufen werden
- zum Beispiel innerhalb von drawSE() - bewirkt aber nur 
eine sichtbare Ausgabe nach einem Aufruf von Start(...) und vor  
der Zeit tend. Durch den ständigen Aufruf innerhalb des drawings
deaktiviert sich die Ausgabe nach tend selbst. 
Der Ausgabeort wird von self.drawfunc() bestimmt, die anlässlich
eines Aufrufs von TimedMessage:init(...) übergeben wird
--]]
function TimedMessage:draw()
if not self.running then return end
if self.running and os.clock() <= self.tend then
if self.i  or self.ip then self.drawfunc{p=self.i,ip=self.ip,hfun=self.hfun} end
else
self.running=false  self.hfun=nil   
end
end
