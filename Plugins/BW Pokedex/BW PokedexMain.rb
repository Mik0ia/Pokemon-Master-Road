#===============================================================================
#
#===============================================================================
class Window_Pokedex < Window_DrawableCommand
  alias bw_style_initialize initialize unless method_defined?(:bw_style_initialize)
  def initialize(x,y,width,height,viewport)
    bw_style_initialize(x,y,width,height,viewport)
    # Changes the color of the text, to the one used in BW
    self.baseColor   = Color.new(222,222,222)
    self.shadowColor = Color.new(132,132,132)
  end

  def drawItem(index, _count, rect)
    return if index >= self.top_row + self.page_item_max
    rect = Rect.new(rect.x + 16, rect.y, rect.width - 16, rect.height)
    species     = @commands[index][:species]
    indexNumber = @commands[index][:number]
    indexNumber -= 1 if @commands[index][:shift]
    if $player.seen?(species)
      if $player.owned?(species)
        pbCopyBitmap(self.contents, @pokeballOwn.bitmap, rect.x - 6, rect.y + 10)
      else
        pbCopyBitmap(self.contents, @pokeballSeen.bitmap, rect.x - 6, rect.y + 10)
      end
      num_text = sprintf("%03d", indexNumber)
      name_text = @commands[index][:name]
    else
      num_text = sprintf("%03d", indexNumber)
      name_text = "----------"
    end
    pbDrawShadowText(self.contents, rect.x + 36, rect.y + 6, rect.width, rect.height,
                     num_text, self.baseColor, self.shadowColor)
    pbDrawShadowText(self.contents, rect.x + 84, rect.y + 6, rect.width, rect.height,
                     name_text, self.baseColor, self.shadowColor)
  end
end

#===============================================================================
# Pokédex main screen
#===============================================================================
class PokemonPokedex_Scene
  def pbStartScene
    @sliderbitmap       = AnimatedBitmap.new("Graphics/UI/Pokedex/icon_slider")
    @typebitmap         = AnimatedBitmap.new(_INTL("Graphics/UI/Pokedex/icon_types"))
    @shapebitmap        = AnimatedBitmap.new("Graphics/UI/Pokedex/icon_shapes")
    @hwbitmap           = AnimatedBitmap.new("Graphics/UI/Pokedex/icon_hw")
    @selbitmap          = AnimatedBitmap.new("Graphics/UI/Pokedex/icon_searchsel")
    @searchsliderbitmap = AnimatedBitmap.new(_INTL("Graphics/UI/Pokedex/icon_searchslider"))
    @sprites = {}
    @viewport = Viewport.new(0, 0, Graphics.width, Graphics.height)
    @viewport.z = 99999
    # CHANGED: Defines the Scrolling Background, as well as the overlay on top of it
    @sprites["background"] = ScrollingSprite.new(@viewport)
    @sprites["background"].speed = 1
    @sprites["infoverlay"] = IconSprite.new(0, 0, @viewport)
=begin
    # Suggestion for changing the background depending on region. You can change
    # the line above with the following:
    if pbGetPokedexRegion==-1   # Using national Pokédex
      addBackgroundPlane(@sprites,"background","Pokedex/bg_national",@viewport)
    elsif pbGetPokedexRegion==0   # Using first regional Pokédex
      addBackgroundPlane(@sprites,"background","Pokedex/bg_regional",@viewport)
    end
=end
    addBackgroundPlane(@sprites, "searchbg", "Pokedex/bg_search", @viewport)
    @sprites["searchbg"].visible = false
    # CHANGED: Y value and height
    @sprites["pokedex"] = Window_Pokedex.new(206, 94, 276, 260, @viewport)
    @sprites["icon"] = PokemonSprite.new(@viewport)
    @sprites["icon"].setOffset(PictureOrigin::CENTER)
    @sprites["icon"].x = 110 # CHANGED: X value
    @sprites["icon"].y = 196
    @sprites["overlay"] = BitmapSprite.new(Graphics.width, Graphics.height, @viewport)
    pbSetSystemFont(@sprites["overlay"].bitmap)
	#pbSetSystemFontBW(@sprites["overlay"].bitmap)
    @sprites["searchcursor"] = PokedexSearchSelectionSprite.new(@viewport)
    @sprites["searchcursor"].visible = false
    @searchResults = false
    @searchParams  = [$PokemonGlobal.pokedexMode, -1, -1, -1, -1, -1, -1, -1, -1, -1]
    pbRefreshDexList($PokemonGlobal.pokedexIndex[pbGetSavePositionIndex])
    pbDeactivateWindows(@sprites)
    pbFadeInAndShow(@sprites)
  end

  alias bw_style_pbRefreshDexList pbRefreshDexList unless method_defined?(:bw_style_pbRefreshDexList)
  def pbRefreshDexList(index = 0)
    bw_style_pbRefreshDexList(index)
    # Sets the overlay list of Pokémon in the Search Mode of the Pokédex
    if @searchResults
      @sprites["infoverlay"].setBitmap("Graphics/UI/Pokedex/listsearch_overlay")
    else
      @sprites["infoverlay"].setBitmap("Graphics/UI/Pokedex/list_overlay")
    end
    pbRefresh
  end

  def pbRefresh
    overlay = @sprites["overlay"].bitmap
    overlay.clear
    # CHANGED: Changes the color of the text, to the one used in BW
    base   = Color.new(49,49,49)
    shadow = Color.new(140,140,140)
    iconspecies = @sprites["pokedex"].species
    iconspecies = nil if !$player.seen?(iconspecies)
    # Write various bits of text
    dexname = _INTL("Pokédex")
    if $player.pokedex.dexes_count > 1
      thisdex = Settings.pokedex_names[pbGetSavePositionIndex]
      if thisdex
        dexname = (thisdex.is_a?(Array)) ? thisdex[0] : thisdex
      end
    end
    textpos = [
      [dexname,20,14,0,Color.new(222,222,222),Color.new(132,132,132)]
    ]
    # CHANGED: Changes various things in text
    # Changes the position of the Species' Names, as well as the color of the text, to mimic the one used in BW
    textpos.push([GameData::Species.get(iconspecies).name,108,336,2,base,shadow]) if iconspecies
    if @searchResults
      # Changes the position of some texts regarding the Search Results of the Search 
      # mode, as well as the color of the text, to mimic the one used in BW
      textpos.push([_INTL("Search results"),126,60,2,base,shadow])
      textpos.push([@dexlist.length.to_s,242,60,2,base,shadow])
    else
      # Changes the position of the Seen/Owned parameters, as well as the color of the 
      # text, to mimic the one used in BW
      textpos.push([_INTL("SEEN"),126,60,0,base,shadow])
      textpos.push([$player.pokedex.seen_count(pbGetPokedexRegion).to_s,242,60,1,base,shadow])
      textpos.push([_INTL("OWNED"),334,60,0,base,shadow])
      textpos.push([$player.pokedex.owned_count(pbGetPokedexRegion).to_s,494,60,1,base,shadow])
    end
    # Draw all text
    pbDrawTextPositions(overlay, textpos)
    # Set Pokémon sprite
    setIconBitmap(iconspecies)
    # Draw slider arrows
    itemlist = @sprites["pokedex"]
    showslider = false
    if itemlist.top_row > 0
      overlay.blt(468, 118, @sliderbitmap.bitmap, Rect.new(0, 0, 40, 30))
      showslider = true
    end
    if itemlist.top_item + itemlist.page_item_max < itemlist.itemCount
      overlay.blt(468, 306, @sliderbitmap.bitmap, Rect.new(0, 30, 40, 30))
      showslider = true
    end
    # Draw slider box
    if showslider
      sliderheight = 220 # CHANGED: Height
      boxheight = (sliderheight * itemlist.page_row_max / itemlist.row_max).floor
      boxheight += [(sliderheight - boxheight) / 2, sliderheight / 6].min
      boxheight = [boxheight.floor, 40].max
      y = 118 # CHANGED: Y value
      y += ((sliderheight - boxheight) * itemlist.top_row / (itemlist.row_max - itemlist.page_row_max)).floor
      overlay.blt(468, y, @sliderbitmap.bitmap, Rect.new(40, 0, 40, 8))
      i = 0
      while i * 16 < boxheight - 8 - 16
        height = [boxheight - 8 - 16 - (i * 16), 16].min
        overlay.blt(468, y + 8 + (i * 16), @sliderbitmap.bitmap, Rect.new(40, 8, 40, height))
        i += 1
      end
      overlay.blt(468, y + boxheight - 16, @sliderbitmap.bitmap, Rect.new(40, 24, 40, 16))
    end
  end

  def pbRefreshDexSearch(params, _index)
    overlay = @sprites["overlay"].bitmap
    overlay.clear
    # # CHANGED: Set font to v20.1 version just for this screen
    # pbSetSystemFont(overlay)
    # CHANGED: Changes the color of the text, to the one used in BW
    base   = Color.new(255,255,255)
    shadow = Color.new(165,165,173)
    # Write various bits of text
    # CHANGED: Added a Y offset to nearly all text values
    #bw_y_offset = -10
    bw_y_offset = -1
    textpos = [
      [_INTL("Search Mode"), Graphics.width / 5, 10 + bw_y_offset, 2, base, shadow], # CHANGED: X value
      [_INTL("Order"), 136, 64 + bw_y_offset, 2, base, shadow],
      [_INTL("Name"), 58, 122 + bw_y_offset, 2, base, shadow],
      [_INTL("Type"), 58, 174 + bw_y_offset, 2, base, shadow],
      [_INTL("Height"), 58, 226 + bw_y_offset, 2, base, shadow],
      [_INTL("Weight"), 58, 278 + bw_y_offset, 2, base, shadow],
      [_INTL("Color"), 326, 122 + bw_y_offset, 2, base, shadow],
      [_INTL("Shape"), 454, 174 + bw_y_offset, 2, base, shadow],
      [_INTL("Reset"), 80, 346 + bw_y_offset, 2, base, shadow, 1],
      [_INTL("Start"), Graphics.width / 2, 346 + bw_y_offset, 2, base, shadow, 1],
      [_INTL("Cancel"), Graphics.width - 80, 346 + bw_y_offset, 2, base, shadow, 1]
    ]
    # Write order, name and color parameters
    textpos.push([@orderCommands[params[0]], 344, 66 + bw_y_offset, 2, base, shadow, 1])
    textpos.push([(params[1] < 0) ? "----" : @nameCommands[params[1]], 176, 124 + bw_y_offset, 2, base, shadow, 1])
    textpos.push([(params[8] < 0) ? "----" : @colorCommands[params[8]].name, 444, 124 + bw_y_offset, 2, base, shadow, 1])
    # Draw type icons
    if params[2] >= 0
      type_number = @typeCommands[params[2]].icon_position
      typerect = Rect.new(0, type_number * 32, 96, 32)
      overlay.blt(128, 168, @typebitmap.bitmap, typerect)
    else
      textpos.push(["----", 176, 176 + bw_y_offset, 2, base, shadow, 1])
    end
    if params[3] >= 0
      type_number = @typeCommands[params[3]].icon_position
      typerect = Rect.new(0, type_number * 32, 96, 32)
      overlay.blt(256, 168, @typebitmap.bitmap, typerect)
    else
      textpos.push(["----", 304, 176 + bw_y_offset, 2, base, shadow, 1])
    end
    # Write height and weight limits
    ht1 = (params[4] < 0) ? 0 : (params[4] >= @heightCommands.length) ? 999 : @heightCommands[params[4]]
    ht2 = (params[5] < 0) ? 999 : (params[5] >= @heightCommands.length) ? 0 : @heightCommands[params[5]]
    wt1 = (params[6] < 0) ? 0 : (params[6] >= @weightCommands.length) ? 9999 : @weightCommands[params[6]]
    wt2 = (params[7] < 0) ? 9999 : (params[7] >= @weightCommands.length) ? 0 : @weightCommands[params[7]]
    hwoffset = false
    if System.user_language[3..4] == "US"   # If the user is in the United States
      ht1 = (params[4] >= @heightCommands.length) ? 99 * 12 : (ht1 / 0.254).round
      ht2 = (params[5] < 0) ? 99 * 12 : (ht2 / 0.254).round
      wt1 = (params[6] >= @weightCommands.length) ? 99_990 : (wt1 / 0.254).round
      wt2 = (params[7] < 0) ? 99_990 : (wt2 / 0.254).round
      textpos.push([sprintf("%d'%02d''", ht1 / 12, ht1 % 12), 166, 228 + bw_y_offset, 2, base, shadow, 1])
      textpos.push([sprintf("%d'%02d''", ht2 / 12, ht2 % 12), 294, 228 + bw_y_offset, 2, base, shadow, 1])
      textpos.push([sprintf("%.1f", wt1 / 10.0), 166, 280 + bw_y_offset, 2, base, shadow, 1])
      textpos.push([sprintf("%.1f", wt2 / 10.0), 294, 280 + bw_y_offset, 2, base, shadow, 1])
      hwoffset = true
    else
      textpos.push([sprintf("%.1f", ht1 / 10.0), 166, 228 + bw_y_offset, 2, base, shadow, 1])
      textpos.push([sprintf("%.1f", ht2 / 10.0), 294, 228 + bw_y_offset, 2, base, shadow, 1])
      textpos.push([sprintf("%.1f", wt1 / 10.0), 166, 280 + bw_y_offset, 2, base, shadow, 1])
      textpos.push([sprintf("%.1f", wt2 / 10.0), 294, 280 + bw_y_offset, 2, base, shadow, 1])
    end
    overlay.blt(344, 214, @hwbitmap.bitmap, Rect.new(0, (hwoffset) ? 44 : 0, 32, 44))
    overlay.blt(344, 266, @hwbitmap.bitmap, Rect.new(32, (hwoffset) ? 44 : 0, 32, 44))
    # Draw shape icon
    if params[9] >= 0
      shape_number = @shapeCommands[params[9]].icon_position
      shaperect = Rect.new(0, shape_number * 60, 60, 60)
      overlay.blt(424, 218, @shapebitmap.bitmap, shaperect)
    end
    # Draw all text
    pbDrawTextPositions(overlay, textpos)
  end

  def pbRefreshDexSearchParam(mode, cmds, sel, _index)
    overlay = @sprites["overlay"].bitmap
    overlay.clear
    # CHANGED: Changes the color of the text, to the one used in BW
    base   = Color.new(255,255,255)
    shadow = Color.new(165,165,173)
    # CHANGED: Added a Y offset to nearly all text values
    #bw_y_offset = -10
    bw_y_offset = -1
    # Write various bits of text
    textpos = [
      [_INTL("Search Mode"), Graphics.width / 5, 10 + bw_y_offset, 2, base, shadow], # CHANGED: X value
      [_INTL("OK"), 80, 346 + bw_y_offset, 2, base, shadow, 1],
      [_INTL("Cancel"), Graphics.width - 80, 346 + bw_y_offset, 2, base, shadow, 1]
    ]
    title = [_INTL("Order"), _INTL("Name"), _INTL("Type"), _INTL("Height"),
             _INTL("Weight"), _INTL("Color"), _INTL("Shape")][mode]
    textpos.push([title, 102, (mode == 6) ? 70 + bw_y_offset : 64 + bw_y_offset, 0, base, shadow])
    case mode
    when 0   # Order
      xstart = 46
      ystart = 128
      xgap = 236
      ygap = 64
      halfwidth = 92
      cols = 2
      selbuttony = 0
      selbuttonheight = 44
    when 1   # Name
      xstart = 78
      ystart = 114
      xgap = 52
      ygap = 52
      halfwidth = 22
      cols = 7
      selbuttony = 156
      selbuttonheight = 44
    when 2   # Type
      xstart = 8
      ystart = 104
      xgap = 124
      ygap = 44
      halfwidth = 62
      cols = 4
      selbuttony = 44
      selbuttonheight = 44
    when 3, 4   # Height, weight
      xstart = 44
      ystart = 110
      xgap = 304 / (cmds.length + 1)
      ygap = 112
      halfwidth = 60
      cols = cmds.length + 1
    when 5   # Color
      xstart = 62
      ystart = 114
      xgap = 132
      ygap = 52
      halfwidth = 62
      cols = 3
      selbuttony = 44
      selbuttonheight = 44
    when 6   # Shape
      xstart = 82
      ystart = 116
      xgap = 70
      ygap = 70
      halfwidth = 0
      cols = 5
      selbuttony = 88
      selbuttonheight = 68
    end
    # Draw selected option(s) text in top bar
    case mode
    when 2   # Type icons
      2.times do |i|
        if !sel[i] || sel[i] < 0
          textpos.push(["----", 298 + (128 * i), 66 + bw_y_offset, 2, base, shadow, 1])
        else
          type_number = @typeCommands[sel[i]].icon_position
          typerect = Rect.new(0, type_number * 32, 96, 32)
          overlay.blt(250 + (128 * i), 58, @typebitmap.bitmap, typerect)
        end
      end
    when 3   # Height range
      ht1 = (sel[0] < 0) ? 0 : (sel[0] >= @heightCommands.length) ? 999 : @heightCommands[sel[0]]
      ht2 = (sel[1] < 0) ? 999 : (sel[1] >= @heightCommands.length) ? 0 : @heightCommands[sel[1]]
      hwoffset = false
      if System.user_language[3..4] == "US"    # If the user is in the United States
        ht1 = (sel[0] >= @heightCommands.length) ? 99 * 12 : (ht1 / 0.254).round
        ht2 = (sel[1] < 0) ? 99 * 12 : (ht2 / 0.254).round
        txt1 = sprintf("%d'%02d''", ht1 / 12, ht1 % 12)
        txt2 = sprintf("%d'%02d''", ht2 / 12, ht2 % 12)
        hwoffset = true
      else
        txt1 = sprintf("%.1f", ht1 / 10.0)
        txt2 = sprintf("%.1f", ht2 / 10.0)
      end
      textpos.push([txt1, 286, 66 + bw_y_offset, 2, base, shadow, 1])
      textpos.push([txt2, 414, 66 + bw_y_offset, 2, base, shadow, 1])
      overlay.blt(462, 52, @hwbitmap.bitmap, Rect.new(0, (hwoffset) ? 44 : 0, 32, 44))
    when 4   # Weight range
      wt1 = (sel[0] < 0) ? 0 : (sel[0] >= @weightCommands.length) ? 9999 : @weightCommands[sel[0]]
      wt2 = (sel[1] < 0) ? 9999 : (sel[1] >= @weightCommands.length) ? 0 : @weightCommands[sel[1]]
      hwoffset = false
      if System.user_language[3..4] == "US"   # If the user is in the United States
        wt1 = (sel[0] >= @weightCommands.length) ? 99_990 : (wt1 / 0.254).round
        wt2 = (sel[1] < 0) ? 99_990 : (wt2 / 0.254).round
        txt1 = sprintf("%.1f", wt1 / 10.0)
        txt2 = sprintf("%.1f", wt2 / 10.0)
        hwoffset = true
      else
        txt1 = sprintf("%.1f", wt1 / 10.0)
        txt2 = sprintf("%.1f", wt2 / 10.0)
      end
      textpos.push([txt1, 286, 66 + bw_y_offset, 2, base, shadow, 1])
      textpos.push([txt2, 414, 66 + bw_y_offset, 2, base, shadow, 1])
      overlay.blt(462, 52, @hwbitmap.bitmap, Rect.new(32, (hwoffset) ? 44 : 0, 32, 44))
    when 5   # Color
      if sel[0] < 0
        textpos.push(["----", 362, 66 + bw_y_offset, 2, base, shadow, 1])
      else
        textpos.push([cmds[sel[0]].name, 362, 66 + bw_y_offset, 2, base, shadow, 1])
      end
    when 6   # Shape icon
      if sel[0] >= 0
        shaperect = Rect.new(0, @shapeCommands[sel[0]].icon_position * 60, 60, 60)
        overlay.blt(332, 50, @shapebitmap.bitmap, shaperect)
      end
    else
      if sel[0] < 0
        text = ["----", "-", "----", "", "", "----", ""][mode]
        textpos.push([text, 362, 66 + bw_y_offset, 2, base, shadow, 1])
      else
        textpos.push([cmds[sel[0]], 362, 66 + bw_y_offset, 2, base, shadow, 1])
      end
    end
    # Draw selected option(s) button graphic
    if [3, 4].include?(mode)   # Height, weight
      xpos1 = xstart + ((sel[0] + 1) * xgap)
      xpos1 = xstart if sel[0] < -1
      xpos2 = xstart + ((sel[1] + 1) * xgap)
      xpos2 = xstart + (cols * xgap) if sel[1] < 0
      xpos2 = xstart if sel[1] >= cols - 1
      ypos1 = ystart + 180 + bw_y_offset
      ypos2 = ystart + 36 + bw_y_offset
      overlay.blt(16, 120, @searchsliderbitmap.bitmap, Rect.new(0, 192, 32, 44)) if sel[1] < cols - 1
      overlay.blt(464, 120, @searchsliderbitmap.bitmap, Rect.new(32, 192, 32, 44)) if sel[1] >= 0
      overlay.blt(16, 264, @searchsliderbitmap.bitmap, Rect.new(0, 192, 32, 44)) if sel[0] >= 0
      overlay.blt(464, 264, @searchsliderbitmap.bitmap, Rect.new(32, 192, 32, 44)) if sel[0] < cols - 1
      hwrect = Rect.new(0, 0, 120, 96)
      overlay.blt(xpos2, ystart, @searchsliderbitmap.bitmap, hwrect)
      hwrect.y = 96
      overlay.blt(xpos1, ystart + ygap, @searchsliderbitmap.bitmap, hwrect)
      textpos.push([txt1, xpos1 + halfwidth, ypos1-12, 2, base, nil, 1])
      textpos.push([txt2, xpos2 + halfwidth, ypos2-12, 2, base, nil, 1])
    else
      sel.length.times do |i|
        selrect = Rect.new(0, selbuttony, @selbitmap.bitmap.width, selbuttonheight)
        if sel[i] >= 0
          overlay.blt(xstart + ((sel[i] % cols) * xgap),
                      ystart + ((sel[i] / cols).floor * ygap),
                      @selbitmap.bitmap, selrect)
        else
          overlay.blt(xstart + ((cols - 1) * xgap),
                      ystart + ((cmds.length / cols).floor * ygap),
                      @selbitmap.bitmap, selrect)
        end
      end
    end
    # Draw options
    case mode
    when 0, 1   # Order, name
      cmds.length.times do |i|
        x = xstart + halfwidth + ((i % cols) * xgap)
        y = ystart + 14 + ((i / cols).floor * ygap) + bw_y_offset
        textpos.push([cmds[i], x, y, 2, base, shadow, 1])
      end
      if mode != 0
        textpos.push([(mode == 1) ? "-" : "----",
                      xstart + halfwidth + ((cols - 1) * xgap),
                      ystart + 14 + ((cmds.length / cols).floor * ygap) + bw_y_offset,
                      2, base, shadow, 1])
      end
    when 2   # Type
      typerect = Rect.new(0, 0, 96, 32)
      cmds.length.times do |i|
        typerect.y = @typeCommands[i].icon_position * 32
        overlay.blt(xstart + 14 + ((i % cols) * xgap),
                    ystart + 6 + ((i / cols).floor * ygap),
                    @typebitmap.bitmap, typerect)
      end
      textpos.push(["----",
                    xstart + halfwidth + ((cols - 1) * xgap),
                    ystart + 14 + ((cmds.length / cols).floor * ygap) + bw_y_offset,
                    2, base, shadow, 1])
    when 5   # Color
      cmds.length.times do |i|
        x = xstart + halfwidth + ((i % cols) * xgap)
        y = ystart + 14 + ((i / cols).floor * ygap) + bw_y_offset
        textpos.push([cmds[i].name, x, y, 2, base, shadow, 1])
      end
      textpos.push(["----",
                    xstart + halfwidth + ((cols - 1) * xgap),
                    ystart + 14 + ((cmds.length / cols).floor * ygap) + bw_y_offset,
                    2, base, shadow, 1])
    when 6   # Shape
      shaperect = Rect.new(0, 0, 60, 60)
      cmds.length.times do |i|
        shaperect.y = @shapeCommands[i].icon_position * 60
        overlay.blt(xstart + 4 + ((i % cols) * xgap),
                    ystart + 4 + ((i / cols).floor * ygap),
                    @shapebitmap.bitmap, shaperect)
      end
    end
    # Draw all text
    pbDrawTextPositions(overlay, textpos)
  end

  def pbDexSearch
    oldsprites = pbFadeOutAndHide(@sprites)
    params = @searchParams.clone
    @orderCommands = []
    @orderCommands[MODENUMERICAL] = _INTL("Numerical")
    @orderCommands[MODEATOZ]      = _INTL("A to Z")
    @orderCommands[MODEHEAVIEST]  = _INTL("Heaviest")
    @orderCommands[MODELIGHTEST]  = _INTL("Lightest")
    @orderCommands[MODETALLEST]   = _INTL("Tallest")
    @orderCommands[MODESMALLEST]  = _INTL("Smallest")
    @nameCommands = [_INTL("A"), _INTL("B"), _INTL("C"), _INTL("D"), _INTL("E"),
                     _INTL("F"), _INTL("G"), _INTL("H"), _INTL("I"), _INTL("J"),
                     _INTL("K"), _INTL("L"), _INTL("M"), _INTL("N"), _INTL("O"),
                     _INTL("P"), _INTL("Q"), _INTL("R"), _INTL("S"), _INTL("T"),
                     _INTL("U"), _INTL("V"), _INTL("W"), _INTL("X"), _INTL("Y"),
                     _INTL("Z")]
    @typeCommands = []
    GameData::Type.each { |t| @typeCommands.push(t) if !t.pseudo_type }
    @heightCommands = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10,
                       11, 12, 13, 14, 15, 16, 17, 18, 19, 20,
                       21, 22, 23, 24, 25, 30, 35, 40, 45, 50,
                       55, 60, 65, 70, 80, 90, 100]
    @weightCommands = [5, 10, 15, 20, 25, 30, 35, 40, 45, 50,
                       55, 60, 70, 80, 90, 100, 110, 120, 140, 160,
                       180, 200, 250, 300, 350, 400, 500, 600, 700, 800,
                       900, 1000, 1250, 1500, 2000, 3000, 5000]
    @colorCommands = []
    GameData::BodyColor.each { |c| @colorCommands.push(c) if c.id != :None }
    @shapeCommands = []
    GameData::BodyShape.each { |s| @shapeCommands.push(s) if s.id != :None }
    @sprites["searchbg"].visible     = true
    @sprites["overlay"].visible      = true
    @sprites["searchcursor"].visible = true
    index = 0
    oldindex = index
    @sprites["searchcursor"].mode    = -1
    @sprites["searchcursor"].index   = index
    pbRefreshDexSearch(params, index)
    pbFadeInAndShow(@sprites)
    loop do
      Graphics.update
      Input.update
      pbUpdate
      if index != oldindex
        @sprites["searchcursor"].index = index
        oldindex = index
      end
      if Input.trigger?(Input::UP)
        if index >= 7
          index = 4
        elsif index == 5
          index = 0
        elsif index > 0
          index -= 1
        end
        pbPlayCursorSE if index != oldindex
      elsif Input.trigger?(Input::DOWN)
        if [4, 6].include?(index)
          index = 8
        elsif index < 7
          index += 1
        end
        pbPlayCursorSE if index != oldindex
      elsif Input.trigger?(Input::LEFT)
        if index == 5
          index = 1
        elsif index == 6
          index = 3
        elsif index > 7
          index -= 1
        end
        pbPlayCursorSE if index != oldindex
      elsif Input.trigger?(Input::RIGHT)
        if index == 1
          index = 5
        elsif index >= 2 && index <= 4
          index = 6
        elsif [7, 8].include?(index)
          index += 1
        end
        pbPlayCursorSE if index != oldindex
      elsif Input.trigger?(Input::ACTION)
        index = 8
        pbPlayCursorSE if index != oldindex
      elsif Input.trigger?(Input::BACK)
        pbPlayCloseMenuSE
        break
      elsif Input.trigger?(Input::USE)
        pbPlayDecisionSE if index != 9
        case index
        when 0   # Choose sort order
          newparam = pbDexSearchCommands(0, [params[0]], index)
          params[0] = newparam[0] if newparam
          pbRefreshDexSearch(params, index)
        when 1   # Filter by name
          newparam = pbDexSearchCommands(1, [params[1]], index)
          params[1] = newparam[0] if newparam
          pbRefreshDexSearch(params, index)
        when 2   # Filter by type
          newparam = pbDexSearchCommands(2, [params[2], params[3]], index)
          if newparam
            params[2] = newparam[0]
            params[3] = newparam[1]
          end
          pbRefreshDexSearch(params, index)
        when 3   # Filter by height range
          newparam = pbDexSearchCommands(3, [params[4], params[5]], index)
          if newparam
            params[4] = newparam[0]
            params[5] = newparam[1]
          end
          pbRefreshDexSearch(params, index)
        when 4   # Filter by weight range
          newparam = pbDexSearchCommands(4, [params[6], params[7]], index)
          if newparam
            params[6] = newparam[0]
            params[7] = newparam[1]
          end
          pbRefreshDexSearch(params, index)
        when 5   # Filter by color filter
          newparam = pbDexSearchCommands(5, [params[8]], index)
          params[8] = newparam[0] if newparam
          pbRefreshDexSearch(params, index)
        when 6   # Filter by shape
          newparam = pbDexSearchCommands(6, [params[9]], index)
          params[9] = newparam[0] if newparam
          pbRefreshDexSearch(params, index)
        when 7   # Clear filters
          10.times do |i|
            params[i] = (i == 0) ? MODENUMERICAL : -1
          end
          pbRefreshDexSearch(params, index)
        when 8   # Start search (filter)
          dexlist = pbSearchDexList(params)
          if dexlist.length == 0
            pbMessage(_INTL("No matching Pokémon were found."))
          else
            @dexlist = dexlist
            @sprites["pokedex"].commands = @dexlist
            @sprites["pokedex"].index    = 0
            @sprites["pokedex"].refresh
            @searchResults = true
            @searchParams = params
            break
          end
        when 9   # Cancel
          pbPlayCloseMenuSE
          break
        end
      end
    end
    pbFadeOutAndHide(@sprites)
    # CHANGED: Sets the Scrolling Background, as well as the overlay on top of it
    if @searchResults
      @sprites["background"].setBitmap("Graphics/UI/Pokedex/bg_listsearch")
      @sprites["infoverlay"].setBitmap(_INTL("Graphics/UI/Pokedex/listsearch_overlay"))
    else
      @sprites["background"].setBitmap("Graphics/UI/Pokedex/bg_list")
      @sprites["infoverlay"].setBitmap(_INTL("Graphics/UI/Pokedex/list_overlay"))
    end
    pbRefresh
    pbFadeInAndShow(@sprites, oldsprites)
    Input.update
    return 0
  end
end
