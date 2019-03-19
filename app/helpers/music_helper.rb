module MusicHelper
  
  def td_class_music_type(item)
    type = item.class.to_s
    if type == 'Track'
      '<td class="track">'
    elsif type == 'Artist'
      '<td class="artist">'
    elsif type == 'Label'
      '<td class="label">'
    elsif type == 'Album'
      '<td class="album">'
    end
  end

end
