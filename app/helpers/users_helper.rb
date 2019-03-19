module UsersHelper
  
  def make_alphabet_index(alpha_map)
    index = ''
    alphabet = alpha_map.keys.sort
    alphabet.each{|a|
      if(alpha_map[a])
        index += '<a href="#'+a+'">'+a+'</a>'
      else
        index += '<span>'+a+'</span>'
      end
    }
    index
  end
  
  def echo_mytags_alphabetical(tags, u_id)
     i = 0
     ret = ''
     fl = ''
     tags.each{|t|
        unless t.name[0,1] == fl
          ret += '</ul>' unless i == 0
          ret += '<h3><a name="'+t.name[0,1].upcase+'">'+t.name[0,1].upcase+'</a></h3><ul>'
        end
        i += 1
        fl = t.name[0,1]
        ret += '<li>'+link_to( t.name, mytag_path(:id => u_id, :tag => t.name) )+'</li>'
     }
     ret
  end
 
  def echo_user_tags_alphabetical(tags, u_id)
     i = 0
     ret = ''
     fl = ''
     tags.each{|t|
        unless t.name[0,1] == fl
          ret += '</ul>' unless i == 0
          ret += '<h3><a name="'+t.name[0,1].upcase+'">'+t.name[0,1].upcase+'</a></h3><ul>'
        end
        i += 1
        fl = t.name[0,1]
        ret += '<li>'+link_to( t.name, tag_user_path(:id => u_id, :tag => t.name) )+'</li>'
     }
     ret
  end
  
  def age_options
    opt = '<option></option><option>under 14</option>'
    for i in 14..50 do
      opt += "<option>#{i}</option>"
    end
    opt += '<option>over 50</option>'
  end
  
  def show_age(user)
    if user.birthday
      integer_style = "%Y%m%d"
      today = Date.today.strftime(integer_style).to_i
      birthday = user.birthday.strftime(integer_style).to_i
      (today - birthday) / 10000
    else
      '<em>unknown</em>'
    end
  end
  
  def show_country(user)
    unless user.country.blank? || user.country == 'unknown'
      user.country
    else
      '<em>unknown</em>'
    end
  end
  
  def show_home(user)
    country = (user.country.blank? || user.country == 'unknown') ? nil : user.country
    unless user.zip.blank? || user.city.blank? || country.nil?
      home = "#{user.zip} #{user.city}, #{country}"
    else
      if country && user.city
        home = "#{user.city}, #{user.country}"
      elsif country
        home = user.country
      else
        home = '<em>unknown</em>'
      end
      home
    end
    
  end
  
  def show_login(time)
    if time
      if current_user && current_user.time_zone
        time.in_time_zone(current_user.time_zone).to_s(:long)
      else
        time.to_s(:long)
      end
    else
      '<em>never</em>'
    end
  end
  
  def show_gender(user)
    unless user.gender == 'unknown'
      user.gender
    else
      '<em>unknown</em>'
    end
  end
  
end