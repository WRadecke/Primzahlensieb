--# PrimeTweens
-- PrimeTweens für Animationen

--[[
Eine sich im Animationsmodus ständig bewegende Anzeige ganz oben 
im Info-Bereich. Es wird die aktuelle Primzahl gezeigt. 
Wenn ein Durchlauf fertig ist, steht die Anzeige still. 
Dieses Objekt wird Live-Zeile genannt.
--]]
function makeLiveTweens()
local wr=wiT+24
lt={
    10.0,spos={x=GB+wr/2,y=hCell/2},epos={x=BI-wr/2,y=hCell/2},
    opts={easing=tween.easing.linear,loop=tween.loop.pingpong}
   }   

end

--[[
Darstellung der sich bewegenden Live-Zeile, das ist
eine Zeile am oberen Rand des (rechten) Info-Bereichs bestehend
aus einer horizontalen grünen Linie mit eingebetteten gelbem
Fenster (Rechteck), dessen Einbettungsposition sich animiert bewegt.
In das Fenster wird die Textdarstellung der aktuellen Primzahl
eingetragen.
--]]
function drawLiveTweens()
local x,y=lt.spos.x,HEIGHT-1-lt.spos.y
local wr=wiT+24
pushStyle()
rectMode(CENTER)
 fill(clr(a.liverect)) 
 stroke(clr(a.liverectborder))
line(GB,y,x-wr/2,y)
line(x-wr/2,y,BI,y)
rect(x,y,wr,hCell)
    
fill(clr(a.liveelli)); stroke(clr(a.liveelliborder)); strokeWidth(1)
--[[--------------------------------------------------------------------------
Die Ellipse zeigt durch ihre Lage (rechts/links) an,
ob Animation aktiv/inaktiv ist. Diese Umschaltung aktiv/inaktiv
kann interaktiv durch Fingerbewegung (rechts/links) bewerkstelligt
werden
--]]
if Animation then ellipse(x+wr/2-7,y,11,15) else ellipse(x-wr/2+7,y,11,15) end -- rechts/links
-------------------------------------------------------------------------------
fill(clr(a.liveprim))
FONT()
fontSize(14)
textMode(CENTER)
local p = navi().prim > 1 and navi().prim or prim
if p > 1 then text(p,lt.spos.x,HEIGHT-1-lt.spos.y) end --aktuelle Primzahl eintragen
if tap1 then
fill(clr(a.multi))
text("⬆️",(GB+x-wr/2)/2,y)  
text("⬇️",(BI+x+wr/2)/2,y)     
end
popStyle()
end

function moveLiverectToMiddle()
    lt.spos.x=(GB+BI)/2
end
