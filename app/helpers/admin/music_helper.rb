module Admin::MusicHelper
  
  def blank_link_to_show_depending_on_type(music)
    link_to music.name, {:controller => "/" + music.type.to_s.downcase.pluralize,
                   :action => 'show',
                   :id => music} ,
                  {:target => 'blank'}
  end
  
  def link_to_show_in_admin(music)
    link_to 'Show', :controller => music.type.to_s.downcase.pluralize,
                    :action => 'show',
                    :id => music
  end
  
  def link_to_edit(music)
    case music
      when Artist
        path = edit_admin_artist_path(music)
      when Track
        path = edit_admin_track_path music
      when Label
        path = edit_admin_label_path music
      when Album
        path = edit_admin_album_path music
    end
    link_to 'Edit', path
  end
  
end
