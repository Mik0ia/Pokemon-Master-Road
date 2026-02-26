#===============================================================================
# BW font methods
#===============================================================================
# Sets a bitmap's font to the system font. Copied from Essentials v19.1
def pbSetSystemFontBW(bitmap)
  bitmap.font.name = MessageConfig.pbGetSystemFontName
  bitmap.font.size = 29
end
