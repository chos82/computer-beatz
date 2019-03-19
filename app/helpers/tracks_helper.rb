module TracksHelper
  
  def echo_track_release_date(item)
    if item.release_date
      item.release_date.year.to_s
    else
      link_to 'enter release date', :action => 'enter_release_date',
                                    :id => item.id
    end
  end
  
  def embed_yv(video, options = {})
      settings = {
        :border => '0',
        :rel => '0',
        :color1 => '0x666666',
        :color2 => '0x666666',
        :hl => 'en',
        :width => 425,
        :height => 373
      }.merge(options)
    
      params = settings.to_query
      %Q(
    <object width="#{settings[:width]}" height="#{settings[:height]}">
        <param name="movie" value="http://www.youtube.com/v/#{video.youtube_id}&#{params}"></param>
        <param name="wmode" value="transparent"></param>
        <embed src="http://www.youtube.com/v/#{video.youtube_id}&#{params}" type="application/x-shockwave-flash" wmode="transparent" width="#{settings[:width]}" height="#{settings[:height]}"></embed>
    </object>
      )
  end
  
end
