--# StartupScreen

--[[
Eine closure-Fabrik für einen Startup-Screen
Es wird eine animierte Spirale gezeigt,
auf der Primzahlen angeordnet sind.
Hat eine table mit 8 Funktionen als Returnwerte, die
die bereits dort wie folgt benannt werden
ssp               zeige (true/false) Primzahlen auf der Spirale
ssups             starte (true/false) StartupScreen
pivot             zeige (true/false) Pivotpunkt während der Animation der Spirale
std:              Standart herstellen für die ersten drei Optionen
tweenSplash:      Starten der Animation des StartupScreens
drawSplash:       Zeichnen der Animation.
splashRunning:    Testen, ob die Animation läuft.
splashEnd:        Stoppen der Animation
Für die ersten 3 Funktionen werden beim Aufruf die angeforderten boolschen 
Werte in ProjectData permanent gespeichert und beim nächsten Start wieder
eingelesen -und somit dann wirksam.  Die 4. Funktion std stellt die Standartwerte
für die ersten 3 wieder her. Aufrufe dieser 4; Funktionen erfolgen
manuell über das Controlpanel z.B. ssp(false) bei "Einen Befehl eingeben"
--]]
function createStartupScreen() 
local pi,c=math.pi,2*hCell/3
local r,xx,yy=0,0,0
local showprimes=readProjectData("showspiralprimes",true)
local showsups=readProjectData("showstartupscreen",true)
local showpivotpoint=readProjectData("showpivotpoint",false) 
local running=false
local id1,id2
local tbl={}
--[[
Punkte auf einer Archimedische Spirale in relativ groben Winkelschritten 
erzeugen. Zuerst pi/4-Schritte, dann pi/8-Schritte. An diesen Punkten 
werden Primzahlen dargestellt.
--]]
for v=pi/4,4*pi,pi/4 do 
    r=v*c; xx=r*math.cos(v); yy=r*math.sin(v);
    tbl[#tbl+1]={x=xx,y=yy,phi=v}
end
for v=4*pi,16*pi,pi/8 do 
    r=v*c; xx=r*math.cos(v); yy=r*math.sin(v);
    tbl[#tbl+1]={x=xx,y=yy,phi=v}        
end
    
local p = wr.wolframTbl(1) -- Bereitstellung der Primzahlen
local point={x=0,y=0}   -- Animations-Subjekt
local function splashEnd()
     if pause then PauseResume() end
     tween.stop(id1);tween.stop(id2) 
     running=false 
end
    
--[[
Interpolation der Spirale zwischen zwei Punkten 
der groben Spirale - codiert in tbl. Gibt der
Spirale durchgehend die richtige Krümmung, 
zumindest bei ausreichender Anzahl n  
der Interpolationspunkte. Die Funktion
berechnet die Interpolationspunkte und
verbindet diese durch Geradensegmente.
Für die Argumente p,q werden jeweils zwei 
aufeinander folgende Elemente von tbl benutzt.
Die Interpolation erfolgt "on the fly":
d.h. während des Zeichnens in der Funktion drawSplash.
--]]    
local function interpol(p,q,n)
    local cc=hCell/3+2
    local w2,h2,wh=W/2,H/2,math.min(W/2,H/2+cc)
    h2 = h2 + cc
    --[[
    die Punkte p und q werden als Start/End-Punkte
    mit in die Interpolationstabelle t aufgenommen.
    Wesentlich ist, dass in p,q die Winkel
    p.phi,q.phi gespeichert sind, sonst würde für
    die Interpolation nicht der richtige Wert r
    für die Interpolationspunkte erzeugt werden können.
        
    Zwischen Startpunkt p und Endpunkt q sollen n
    Interpolationspunkte liegen aber es sind n+1
    Zwischenabschnitte. 
    p---ip1---ip2---,...,---ip(n-1)---ipn----q
    | 1  |  2  |  3      n-1 |      n  | n+1 |
    "Zwischen n+2 Zaunpfosten liegen n+1 Zaunfelder"
    Daher delta=(q.phi-p.phi)/(n+1)
    --]]
    
    local t={{x=p.x,y=p.y}}  -- p ist Startpunkt
    delta=(q.phi-p.phi)/(n+1)
    local v,r,xx,yy=0,0,0,0
    for i=1,n do
        v=p.phi+i*delta;
        r=c*v; 
        xx=r*math.cos(v); 
        yy=r*math.sin(v); 
        t[#t+1]={x=xx,y=yy}
    end
    t[#t+1]={x=q.x,y=q.y}    -- q ist Endpunkt
    
    for i=2,#t do
        line(t[i-1].x,t[i-1].y,t[i].x,t[i].y)      
    end
    --[[ Anzahl der Interpolationspunkte n in der Mitte anzeigen
        Im sichtbaren Teil kommt ein Maximum von 66 zustande
    if n > 9 then
        local j=math.floor(#t/2)
        pushStyle()
        fill(clr(a.bg))
        strokeWidth(2); stroke(clr(3))
        rectMode(RADIUS)
        local w,h=textSize(tostring(n))
        rect(t[j].x,t[j].y,w/2+2,h/2+2)
        fill(clr(1))
        text(n,t[j].x,t[j].y)
        popStyle()  
    end
    --]]
end
local function sp(bshow) 
showprimes=bshow 
saveProjectData("showspiralprimes", showprimes )      
end   
local function su(bshow)
showsups=bshow
saveProjectData("showstartupscreen",showsups)       
end   
local function pv(bshow)
showpivotpoint=bshow 
saveProjectData("showpivotpoint",showpivotpoint)       
end
local function std() 
showprimes=true
showpivotpoint=false
showsups=true  
saveProjectData("showspiralprimes", showprimes ) 
saveProjectData("showstartupscreen",showsups) 
saveProjectData("showpivotpoint",showpivotpoint)    
end
local function spiralindex() -- index zum aktuellen Muster der Spirale zurück geben
local i=0
if showsups then
i=showprimes and 1 or 3
i = i + (showpivotpoint and 1 or 0)
end 
return i
end
    
--[[
Boolean options für Spirale gemäß
index i setzen.
--]]    
local function setSU(i)
su( i > 0); sp(i <= 2 ); pv(i%2 == 0)
end
    
--[[
Spiralmuster-Index per tap ändern
--]]    
local function tap(touch)
local i,right=spiralindex(),touch.x >=(BI+WIDTH)/2
setSU(
      (right and i < 4) and i+1 
        or 
      ((not right and i > 0 ) and i-1 or i)
     )     
end   

return -- Eine table mit 8 Funktionen wird zurückgegeben
{      -- Es werden jeweils die im setup vergebenen Funktionsnamen als Kommentare angeschrieben.  
sp=sp,
pv=pv,
su=su,
std=std,
tap=tap,
spiralindex=spiralindex,
splashEnd = splashEnd, -- Animation beenden
splashRunning=function () return running end,    -- splashRunning, Abfragen ob Animation läuft
tweenSplash=function () -- Animation der Spirale starten.
--[[
point ist das Subjekt das durch die Animation - in 
Raumzeit unsichtbar bewegt wird. Der Anfangwert von point
spielt keine Rolle. Er wird zum Start auf den ersten Punkt
des Pfades gesetzt. Das ist hier tbl[1].
--]]
if not showsups then return end
id1=tween.path(5.0,point,tbl,{easing=tween.easing.linear,loop=tween.loop.pingpong}) 
id2=tween.delay(30,splashEnd)   -- Beendet sich nach 30 Sekunden selbst,
                                -- oder durch Fingertippen in die Spirale
running=true
tween.play(id1)
tween.play(id2)  
end,
    
drawSplash=function ()       -- animiertes Zeichnen der Spirale
local cc=hCell/3+2
local w2,h2,wh=W/2,H/2,math.min(W/2,H/2+cc)
h2=h2+cc
pushStyle()
pushMatrix()
local act=colortables.act
-- ich und ichich sind Bilder meines Namenskürzels
if act==1 then sprite(ich,W-50,50,50) else  sprite(ichich,W-50,50,50) end
if act==1 then sprite(euler6,80,H-80,200,160) else sprite(euler5,80,H-80,200,160) end
translate(w2,h2)    -- w2,h2 ist die Mitte (h2 nur näherungsweise)
                    -- translate verschiebt alle Koordinaten: (x,y)---> (x+w2,y+h2)
fill(clr(2))
FONT(2)
fontSize(gfntsize)
textMode(CENTER)
local rr=(point.x)^2+(point.y)^2    -- point ist der animierte Punkt- der pivot-Punkt
                                    -- quadratischer Abstand von point 
                                    -- zum Zentrum der Spirale
strokeWidth(4)                      -- Strichbreite der Spirale
stroke(clr(a.liveline))             -- Farbe der Spirale
local n=0  

for i=2,#tbl do
    local ss=(tbl[i].x)^2+(tbl[i].y)^2 -- quadratische Abstand von tbl[i] zum Zentrum derSpirale
    if ss > rr or ss > wh^2 then break end 
    --[[
    Alle Punkte, die auf der Spirale weiter innen sind als 
    das Animationssubjekt point - entsprechend ss <= rr - 
    werden gezeigt. Der Punkt point wird (zumindest zum Anfang)
    von innen nach aussen animiert bewegt. Anschliessend im 
    pingpong von aussen nach innen, usw. Das ist ein Beispiel dafür,
    dass das Animationssubjekt völlig unter der Tarnkappe bleibt.
    --]]
    local s=math.sqrt(ss) 
    --[[
    Dynamische Festlegung der Anzahl n
    der Interpolationspunkte in Abhängigkeit
    von der zu überbrückenden Strecke. Als
    Streckenmass wird die Länge s der Sehne
    zwischen den zu interpolierenden Punkten
    genommen. 
    --]]
    n=math.ceil(s/8)+1     
    interpol(tbl[i-1],tbl[i],n)   
end 
if showprimes then -- Primzahlen einzeichnen
    rectMode(RADIUS)
    for i=1,#tbl do 
        local ss=(tbl[i].x)^2+(tbl[i].y)^2
        if ss > rr or ss > wh^2 then break end
        fill(clr(a.bg))
        strokeWidth(2); stroke(clr(3))
        local w,h=textSize(tostring(p[i]))
        -- Das gefüllte Rechteck soll die Spirale überdecken.
        rect(tbl[i].x,tbl[i].y,w/2+2,h/2+2)
        fill(clr(2))
        text(p[i],tbl[i].x,tbl[i].y) 
    end
end
if showpivotpoint then
    noStroke()
    fill(0,255,0,120)
    ellipseMode(RADIUS)
    ellipse(point.x,point.y,10,10)
end
popMatrix()
popStyle()
end
}
end
