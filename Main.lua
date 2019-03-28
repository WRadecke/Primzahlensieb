--# Main
-- Primzahlensieb

--[[
Globale Objekte sind:
N                   -- Siebgröße = Obergrenze der zu siebenden Zahlen
wCell,hCell,wiT,hiT -- verschiedene Schriftbreiten/Schrifthöhen
wsT                 -- Für ein führendes Leerzeichen in jeder Zeile der Primzahlliste
fntsize             -- 12 oder 14 je nach Größe von N für Info-Bereich
ff                  -- eine Anzahl von Dezimalstellen für die Primzahlenliste
gfntsize            -- 18 für Gitter
prim                -- aktuelle Primzahl        
countprimes         -- Anzehl der gefundenen Primzahlen
prim_countprimes    -- Ein Text der Form 13 / 6
twinpairs           -- Anzahl der gefundenen Primzahlzwillinge
running             -- zeigt eine laufende Animation an
fertig              -- zeigt Ende des Siebens an
zwillinge           -- Primzahlzwillinge solen gezeigt werden
tap1                -- boolean für Inspektionsmodus
pause               -- zeigt an dass eine Animation gerade pausiert      
NichtPrimzahlen_Tarnen  -- fordert Nichtprimzahlen im Gitter unsichtbar zu machen
Animation           -- Fordert Animation
vorheriges          -- zwei aufeinander folgende 
vielfaches          -- Vielfache
GB                  -- Gitterbreite
BI                  -- rechter Rand des Info-Bereiches
H                   -- aktuelle Fensterhöhe
yThirdBottom,yThirdMiddle yThirdTop     -- Mitteldrittel-Werte
spos,epos           -- für animierbare Rechtecke um Gitterzellen
-- und die Tabellen:----------------------------------------------------------------
colortables         -- für zwei verschiedenen Farbschemata
SE                  -- Diese Tabelle ist der wichtigste Zustand während des Siebens.
pt                  -- Tabelle der gefundenen Primzahlen,{2,3,5,...}
lt                  -- table der Livetweens
gr                  -- GridScrollrange
ir                  -- InfoScrollrange
-- und die von closure-Fabriken  erzeugte Funktionen --------------------
makenext()          -- für die nächste Primzahl
m(i)                -- Auslesen des Siebzustands von i
setm(i,v)           -- Setzen des Siebzustands von i
initBit()           -- Rückgabe des Initialisierungszustand für alle i in SE
pr(i)               -- zum Auslesen der Primzahlen aus der table pt
isTwinAt(i)         -- zum Testen auf Primzahlzwillinge in pt
isTwin(i)           -- Testen auf Primzahlzwillinge im Gitter
function-table ic   -- für InfoComponents
function-table wr   -- für wolfram-Test  
function-table nv   -- Zur Navigation im Inspektionsmodus
function-table tk   -- Funktionen für Zeitmessung
function-table su   -- für den StartupScreen
--]]
function setup()
------------ for debugging ---------
-- siehe: https://codea.io/talk/discussion/9168/utilities#latest
--print(readGlobalData("dbugData"))
--stop()
gstr=""
------ sprites für StartupScreen ---------------------------------------
ich=readImage("Documents:ich")
ichich=readImage("Documents:ichich")
euler5=readImage("Documents:euler5")
euler6=readImage("Documents:euler6")
Sp1=readImage("Documents:Spirale5")
Sp2=readImage("Documents:Spirale6")
Sp3=readImage("Documents:Spirale8")
Sp4=readImage("Documents:Spirale7")
spirales={Sp1,Sp2,Sp3,Sp4}
------------------------------------------------------------------------
defineColorTables()   -- für zwei Farbschemata
tk=createTimeKeeper() -- für Zeitmessungen
N=310               -- initiale Siebgröße     
gTM=TimedMessage(gFunc,0,-1,10.0)  -- Bestandteil des Inspektions-Modus.
iTM=TimedMessage(iFunc,0,-1,10.0)  -- Bestandteil des Inspektions-Modus.   
prepareGridComponents()  -- ruft auch createGridScrllrange() auf
volldurchlauf=false
--[[ -------------------------------------------------------------------
Eine closure-Fabrik für alle "Bit-Funktionen", Kapselt die benutzen
konstanten "Bits", die danach nicht mehr explizit im Code
auftauchen müssen.
--]]
local function allBitFuncs()
local initbit=0x2000000000000000
local clearbits=~(3<<60)
local lbits=0x7FFFFFFFFFFFFFFF
local hbit=0x8000000000000000
local mbits = 3<<60
local primbit,twinbit = 1<<60, 1<<63
return 
{
function (i,v) SE[i] = v<<60 end, --((clearbits&SE[i])|(v<<60)) end,
function () return initbit end,
function (n) return lbits&pt[n] end,
function (i) return hbit&pt[i]==hbit and true or false end, 
function (i)  return (mbits&SE[i]) >> 60 end,
function (i)  return   primbit&SE[i] ~= 0 end,
function (i)  return   twinbit&SE[i] ~= 0 end,
function (i)  return (SE[i] & (~(primbit|twinbit))) end
}
end
setm,initBit,pr,isTwinAt,m,isPrim,isTwin,pp=unpack(allBitFuncs())
------------------------------------------------------------------------

nv=Navigation() -- nv ist function-table with named functions
ic=prepareInfoComponents() -- ruft auch createInfoScrollrange() auf
CI=clrindextwin
spos={x=X(1),Y(1)}
epos={x=X(1),y=Y(1)}
parameter.boolean("Farbschema",false,setFS)
parameter.integer("N",100,1000,310,setN)
parameter.action("Einzelschritt",Weiter)
parameter.action("Volldurchlauf", allessieben)
parameter.action("pause-weiter",PauseResume)
parameter.boolean("NichtPrimzahlen_Tarnen",false,tarnenChanged)
parameter.boolean("Animation",true,Ani)
parameter.boolean("zwillinge",true,Zwillis)
parameter.watch("prim_countprimes")
parameter.watch("vielfaches")
pasteboard.copy("gm{ip=1000,ani=true}")
-- pasteboard.copy("gm{p= 8388608,true}")
N=readProjectData("sievesize",310)
setN(N)
makeLiveTweens()
liveid=tween(lt[1],lt.spos,lt.epos,lt.opts)  
tween.stop(liveid)
--testWolfram,wolframTbl,compareResult
wr=createTailCompare() -- wr ist eine function-table mit benannten Funktionen.
                       -- Test auf Übereinstimmung von einem Ende von pt mit 
                       -- einer entsprechenden Tabelle aus der WOLFRAM CLOUD
-- Ein Tip aus codea.io: sehr nützlich ---------------------------------------------------
local update,noop = tween.update,function() end
tween.pauseAll = function()
    tween.update = noop
end
tween.resumeAll = function()
    tween.update = update
end
------------------------------------------------------------------------------------------
W=WIDTH
H=HEIGHT
ss=setN -- merke: ss = sieve size; ss ist leichter im control panel zu schreiben als setN
su=createStartupScreen() -- su ist eine function-table mit benannten Funktionen
su.tweenSplash() -- StartupScreen (eventuell- falls configuriert - ) starten.
end


-- for debugging ------------------
function dBug(s)
    gstr=s.."\n"..str
    gstr=string.sub(gstr,1,200)
    saveGlobalData("dbugData",gstr)
end

--[[
Alles auf Anfangszustand setzen, aber nicht N zurücksetzen.
Das aktuelle Farbschema wird auch nicht zurück gesetzt.
--]]
function reset() 
    gTM.running,iTM.running=false,false
    algoreset()
    ic.inforeset() 
    wiT,hiT,wsT,yTop,fntsize,ff=ic.IC(N) -- InfoComponents
    gr:adjustRange()
    ir:adjustRange() 
    if spos then spos.x,spos.y=X(1),Y(1) end
    if epos then epos.x,epos.y=X(1),Y(1) end
    defineThirdsLines()
    updateTitle()
    nv.navireset()
end

--[[
Obergrenze des zu siebenden Zahlenbereichs auf den Wert von k setzen.
Wird auch von aussen aufgerufen durch eine interaktive Eingabe der Form:
"setN(299)" (299 als Beispiel) im linken Bildschirmstreifen (side bar) des 
laufenden Programms. Beschränkt praktisch die Siebgröße auf maximal 10 Millionen.
--]]
function setN(k,save)
k = k or 9999999 -- Höchstwert setzen, falls k nicht angegeben.
k = k <= 9999999 and k or 9999999
N=math.floor(k)
makenext=createMakenext(1)
reset()
if save then
saveProjectData("sievesize",N)       
end
end

--[[
Zwei Funktionen zur Farbauswahl für Zahlen im Gitter.
Wenn zwillinge=true ist, muss clrindextwin verwendet
werden, ansonsten clrindexnorm. In Zwillis(val) wird
die  richtige aktuell zu benutzende Funktion der 
Funktionsvariablen CI zugewiesen. CI(i) wird dann 
immer verwendet. Damit wird vermieden, den Wert von 
zwillinge permanent während des "drawings" abzufragen.
--]]
function clrindexnorm(i) return m(i)+1 end
function clrindextwin(i) return m(i) + (isTwin(i) and 3 or 1) end

--[[
This function gets called when the device orientation changes
Die Function wird schon vor setup() aufgerufen, was eher ärgerlich ist
--]]
function sizeChanged( newOrientation )
if not H then return end -- H wird erst am Ende von setup() gesetzt - auf den Wert von HEIGHT.
OnSizeChanged()  
end

--[[
Das Konzept dieser Funktion lautet: Bewahrung der vertikalen Identität bei
Orientierungswechsel des iPads. Mit einem Vergleich ausgedrückt bedeutet das:

Falls auf dem Bildschirm des iPads ein Passbild einer Person abgebildet würde,
und die Nasenspitze der Person genau in der vertikalen Bildmitte erscheint,
so wird nach einem Orientierungswechsel des iPads in der neuen Orientierung die
Nasenspitze ebenfalls in der (neuen) vertikalen Bildmitte erscheinen. Auch die 
Augen und die Kinnpartie werden relativ zur neuen Bildmitte in derselben vertikalen
Position relativ zur neuen vertikalen Bildmitte erscheinen, wie es vor dem
Orientierungswechsel war - sofern Augen und Kinnpartie in beiden Orientierungen zu
sehen sind/waren. Für die horizontalen Positionen (zum Beispiel der Augen) gilt das 
Gleiche, ohne dass dazu etwas programmtechnisch unternommen werden muss.
Das Ziel des Konzepts wird durch geeignetes programmgesteuertes Scrollen erreicht.
Falls der Scrollrange zu klein ist, wird das nur soweit erreicht, wie der 
Scrollrange es zulässt.

Das konzeptionelle Ziel wird für das Gitter und die Primzahltabelle im Infobereich
ausgeführt - diese sind an die Stelle des Passbildes aus dem Vergleich zu setzen.
Die "Nase" ist am rechten Rand der mittleren Gitterzeile grün markiert und am rechten
Rand der Primzahltabelle durch einen kleinen Bindestrich markiert. Wenn außerdem noch
der ganz rechte Bereich Zusatz-Info gezeigt wird - z.B. im iPad-Landschafts-Modus - 
kennzeichnet der dicke grüne Pfeil auch die vertikale Mitte (die "Nase").
--]]
function OnSizeChanged()
local iMiddle,gMiddle
if H ~= HEIGHT or W ~= WIDTH then -- W,H ist noch die alte Höhe vor dem Orientierungswechsel
    gMiddle=10*math.ceil((gr.Y-H/2)/wCell)
    iMiddle=5*math.ceil((ir.Y-H/2)/hiT)
    W = WIDTH
    H = HEIGHT
    if Animation and running then
    tween.pauseAll()      
end  
yTop=HEIGHT-1-hCell-3*hiT     
defineThirdsLines()
gr:adjustRange()
if prim == 1 then scrollGridTo(gr.yMin) 
else
  if gMiddle then local _,y=XY(gMiddle) scrollGridTo(y + HEIGHT/2) end
end
ir:adjustRange() 
if prim == 1 then scrollInfoTo(ir.yMin) 
else 
  if iMiddle then local _,y=pXY(iMiddle) scrollInfoTo(y + HEIGHT/2) end  
end      
tween.resumeAll()       
end    
end

--[[
Ermittelt die Anzahl der noch nicht behandelten Zahlen > s.
Wenn die Funktion in "dem" geeigneten Siebzustand aufgerufen wird,
ist die ermittelte Anzahl identisch mit der Anzahl der noch nicht 
erkannten Primzahlen.
"Der" geeignete Siebzustand wird in den beiden Funktionen
simpleimmerWeiter() und animateimmerWeiter() abgepasst.
--]]
function eCount(s)
s=s or prim
local n=0
for i=s+1,N do  if m(i)==2 then n = n + 1 end end   
return n
end

--[[
Zum Aufruf von eCount() in geeigneter Situation,
je nach "animate" oder "simple".
Das Argument a spezifiziert "animate", falls angegeben.
Die Benutzung von ecount ist algorithmisch entbehrlich und
zeigt nur dem Benutzer in der Überschrift der Primzahlliste,
dass sich das Sieb in der Endphase befindet.
--]]
function ECount()
if ecount then return end
local f,n = pr(#pt-1),prim -- Bedeutung: first,next
if f*f <= N and n*n > N then
    ecount=eCount() -- eCount() soll nur ein einziges Mal aufgerufen werden.
    ecount = ecount + countprimes  -- jetzt ist ecount Vorhersage für countprimes  
end
end

--[[
Gebunden an Schiebeschalter "Animation". 
Falls während einer laufenden Animation auf "false"
geschaltet wird, wird - unanimiert - der laufenden 
Einzelschritt vollendet und auf weiteren Volldurchlauf 
verzichtet.
--]]
function Ani(val)
    Animation=val
end

--[[
Callback für die Schaltfläche "pause-weiter"
Pausieren oder Fortsetzen einer laufenden Animation.
Der Wert pause==true gibt an, dass die Animation gerade pausiert.
--]]
function PauseResume()
if Animation then
local pr = pause and tween.resumeAll or tween.pauseAll
pr()
pause = not pause and true or false
end
end

--[[
Zeichnet alle vorgesehenen Elemente des Siebvorgangs
in das Hauptfenster.
--]]
function draw() 
repairSE()
background(clr(a.bg))
if su.splashRunning() then 
    su.drawSplash()   -- StartupScreen zeigen   
else               -- Normale "Arbeitsoberfläche" zeigen.
    drawTip()
    drawGrid()
    drawSE()
    gTM:draw()
    drawspos()
    if prim > 1 and prim*prim <= N then kennzeichneVielfache(prim) end  
    local rsprim=nv.navi().prim
    if rsprim > 1 and rsprim*rsprim <= N then kennzeichneVielfache(rsprim) end
    iTM:draw()
    drawLiveTweens()
    drawThirdsLines()
    drawTap1()
    drawPrimes()
    drawTitleandCountPrimes()
    drawSpiralMuster(su.spiralindex())
    if fertig then 
        drawEndmeldung()
        tk.draw()
        drawTestText()
        nv.drawNaviResults() 
        nv.drawPrimefactors()
    end 
end
end

-- Hilfsfunktionen --------------------------------------------
--[[
Signalisiert ein Nutzeranforderung zum Abbruch einer Animation.
Abgebrochen wird hier aber noch nichts.
--]]
function aniAbort()
if Animation and running then
   aniaborted=true 
end 
end

--[[
Aufruf an Ende einer Animation mittels des tween-Systems
--]]
function aniFinish()
if nextprim > 0 then prim=nextprim end
end

--[[
Unterbrechung und weitermachen ermöglichen
--]]
function unterbrechung()
if Animation and running then 
    tween.resetAll()
    if pause then PauseResume() end
    Animation=false
    volldurchlauf=false
    running=false 
    aniFinish()
    simplestreicheVielfache(prim)    
end  
end

--[[
Abbruch und Neustart von Anfang an ermöglichen.
--]]
function abbruch()
tween.stop(liveid) tween.resetAll() reset()    
end
--[[
Zwei Funktionen zum Überprüfen des Ergebnis einer Aufgabe 
aus der Mathematikolympiade 2018 (Klasse 5, Carolin)
--]]
function a1(n,c)
local c=c or "1"
local str=tostring(n)
local a=0
for c in str:gmatch(c) do
    a=a+1
end 
return a
end
--[[
Aufgabe: Wieviel Ziffern 1 werden ausgedruckt, wenn alle ganzen Zahlen
von 1 bis 2018 ausgedruckt werden. Die Funktion A1 berechnet diese 
Anzahl zu 1611. Das bestätigt gedankliche Überlegungen die zur Lösung
der Aufgabe 580513 c) verwendet werden können. 
Vergleiche MO-2018.pdf in Goodreader auf diesem iPad.
--]]
function A1(m,c)
local c= c or "1"
local a=0
for i=1,m do a=a+a1(i,c) end
return a
end
-- Ende Hilfsfunktionen ----------------------------------------
