#===============================================================================
# Pokédex Regional Dexes list menu screen
# * For choosing which region list to view. Only appears when there is more
#   than one accessible region list to choose from, and if
#   Settings::USE_CURRENT_REGION_DEX is false.
#===============================================================================

class Window_DexesList < Window_CommandPokemon
  alias bw_style_initialize initialize unless method_defined?(:bw_style_initialize)
  def initialize(commands, commands2, width)
    bw_style_initialize(commands, commands2, width)
    # Changes the color of the text, to the one used in BW
    self.baseColor   = Color.new(255,255,255)
    self.shadowColor = Color.new(165,165,173)
  end

  def drawItem(index, count, rect)
    super(index, count, rect)
    if index >= 0 && index < @commands2.length
      pbDrawShadowText(self.contents, rect.x + 254, rect.y, 64, rect.height,
                       sprintf("%d", @commands2[index][0]), self.baseColor, self.shadowColor, 1)
      pbDrawShadowText(self.contents, rect.x + 350, rect.y, 64, rect.height,
                       sprintf("%d", @commands2[index][1]), self.baseColor, self.shadowColor, 1)
      allseen = (@commands2[index][0] >= @commands2[index][2])
      allown  = (@commands2[index][1] >= @commands2[index][2])
      pbDrawImagePositions(
        self.contents,
        [["Graphics/UI/Pokedex/icon_menuseenown", rect.x + 236, rect.y + 6, (allseen) ? 26 : 0, 0, 26, 26],
         ["Graphics/UI/Pokedex/icon_menuseenown", rect.x + 332, rect.y + 6, (allown) ? 26 : 0, 26, 26, 26]]
      )
    end
  end
end

#===============================================================================
#
#===============================================================================

class PokemonPokedexMenu_Scene
  def pbStartScene(commands, commands2)
    @commands = commands
    @viewport = Viewport.new(0, 0, Graphics.width, Graphics.height)
    @viewport.z = 99999
    @sprites = {}
    # CHANGED: Defines the Scrolling Background, as well as the overlay on top of it
    @sprites["background"] = ScrollingSprite.new(@viewport)
    @sprites["background"].setBitmap(_INTL("Graphics/UI/Pokedex/bg_menu"))
    @sprites["background"].speed = 1
    @sprites["menuoverlay"] = IconSprite.new(0, 0, @viewport)
    @sprites["menuoverlay"].setBitmap(_INTL("Graphics/UI/Pokedex/menu_overlay"))
    @sprites["headings"] = Window_AdvancedTextPokemon.newWithSize(
      _INTL("<c3=FFFFFF,A5A5AD>SEEN<r>OBTAINED</c3>"),286,136,208,64,@viewport
    )
    @sprites["headings"].windowskin = nil
    @sprites["commands"] = Window_DexesList.new(commands, commands2, Graphics.width - 84)
    @sprites["commands"].x      = 40
    @sprites["commands"].y      = 192
    @sprites["commands"].height = 192
    @sprites["commands"].viewport = @viewport
    pbFadeInAndShow(@sprites) { pbUpdate }
  end
end
