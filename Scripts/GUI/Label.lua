--Styles declared in engine
--[[
LABEL_LEFT=0
LABEL_TOP=0
LABEL_CENTER=1
LABEL_RIGHT=2
LABEL_MIDDLE=4
LABEL_BOTTOM=8
LABEL_WRAP=16
]]

Script.style=0

function Script:Draw(x,y,width,height)
	local gui = self.widget:GetGUI()
	local pos = self.widget:GetPosition(true)
	local sz = self.widget:GetSize(true)
	local scale = gui:GetScale()
	local text = self.widget:GetText()
	local indent=4
	local style = self.style

	gui:SetColor(0.7,0.7,0.7)

	if self.And(style,LABEL_BORDER) then
		gui:DrawRect(pos.x,pos.y,sz.width,sz.height,1)
	end

	if text~="" then
		local drawstyle=0

		if self.And(style,LABEL_CENTER) then drawstyle = drawstyle + Text.Center end
		if self.And(style,LABEL_RIGHT) then drawstyle = drawstyle + Text.Right end
		if self.And(style,LABEL_MIDDLE) then drawstyle = drawstyle + Text.VCenter end
		if self.And(style,LABEL_BOTTOM) then drawstyle = drawstyle + Text.Left end

		--if self.align=="Left" then style = Text.Left end
		--if self.align=="Center" then style = Text.Center end
		--if self.align=="Right" then style = Text.Right end
		--if self.valign=="Center" then style = style + Text.VCenter end
		
		if self.And(style,LABEL_WRAP) then drawstyle = drawstyle + Text.WordWrap end
		
		if self.And(style,LABEL_BORDER) then
			gui:DrawText(text,pos.x+scale*indent,pos.y+scale*indent,sz.width-scale*indent*2,sz.height-scale*indent*2,drawstyle)	
		else
			gui:DrawText(text,pos.x,pos.y,sz.width,sz.height,drawstyle)	
		end
	end
end

function Script.And(set, flag)
	return set % (2*flag) >= flag
end
