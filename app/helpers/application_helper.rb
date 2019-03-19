# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  
  include TagsHelper
  
  #def default_url_options(options = nil)
  #  @controller.send(:default_url_options, options)
  #end
  
  def page_title
    '<title>Computer-Beatz' + title_text + '</title>'
  end
  
  def title_text
    @page_title ? " | #{@page_title}" : ' | Community, Weblabel, Music Database'
  end
  
  def meta(name, content)
    %(<meta name="#{name}" content="#{content}" /> )
  end
  
  def meta_description
    if @label && @label.type == Label
      "Socially and collaboratively find and generate information " +
      "about the Label #{h @label.name}. Tag, comment, rate and make favourites."
    elsif @track && @track.type == Track
      ret = "Socially and collaboratively find and generate information " +
            "about the Track #{h @track.name}"
      ret += ", by #{h @track.artist.name}" if @track.artist
      ret += ", on #{h @track.label.name}" if @track.label
      ret += ". Tag, comment, rate and make favourites."
      ret
    elsif @artist && @artist.type == Artist
      "Socially and collaboratively find and generate information " +
      "about the Artist #{h @artist.name}. Tag, comment, rate and make favourites."
    elsif @album && @album.type == Album
      ret = "Socially and collaboratively find and generate information " +
            "about the Album #{h @album.name}"
      ret += ", by #{h @album.artist.name}" if @album.artist
      ret += ", on #{h @album.label.name}" if @album.label
      ret += ". Tag, comment, rate and make favourites."
      ret
    elsif @group
      "Computer-Beatz Network: Informations about Group #{h @group.title}."
    elsif @topic
      "Computer-Beatz Network: Informations about Group #{h @topic.group.title} - #{h @topic.title}."
    elsif @project
      "Computer-Beatz Weblabel: Fan page of Project #{h @project.name}."
    elsif @release
      "Computer-Beatz Weblabel: #{h @release.project.name} - #{h @release.name}."
    else
      "Database for (electronic) music, social network, weblabel."
    end
  end

  def meta_keywords
    if @label && @label.type == Label
      key = [@label.name]
    elsif @track && @track.type == Track
      key = [@track.name]
      key << @track.artist.name if @track.artist
      key << @track.release_date.year.to_s if @track.release_date
    elsif @artist && @artist.type == Artist
      key = [@artist.name]
    elsif @album && @album.type == Album
      key = [@album.name]
      key << @album.artist.name if @album.artist
      key << @album.label.name if @album.label
      key << @album.release_date.year.to_s if @album.release_date
    elsif @group
      key = [@group.title]
    elsif @topic
      key = [@topic.title, @topic.group.title]
    end
    key ||= []
    (key + %w(weblabel database community social network music electronic electro techno house)).join(',')
  end
  
  def show_latest_creations
    @l_music = Music.find(:all, :order => ['created_at DESC'], :limit => 5)
    @l_users = User.find(:all, :order => ['last_login DESC'], :limit => 3)
    unless params[:controller] == 'releases' && params[:action] == 'index'
      @l_releases = Release.find(:all, :conditions => ["state = 'released'"], :order => ["created_at DESC"], :limit => 3)  
    end
    @l_news = NewsMessage.find(:all, :order => ['created_at DESC'], :limit => 3)
    unless params[:controller] == 'newsletter'
      @l_newsletters = Newsletter.find(:all, :order => ['created_at DESC'], :limit => 2)
    end
    #@latest = music + users + releases + news
    #@latest.sort!{|x,y|
    #  comp_x = x.attribute_present?(:last_login) ? x.last_login : x.created_at 
    #  comp_y = y.attribute_present?(:last_login) ? y.last_login : y.created_at
    #  comp_x <=> comp_y
    #}
    render :partial => 'layouts/right_column/latest_creations'
  end
  
  def echo_div_depending_on_type(item)
    type = item.class.to_s
    if type == 'Track'
      '<div class="l_track">'
    elsif type == 'Artist'
      '<div class="l_artist">'
    elsif type == 'Label'
      '<div class="l_label">'
    elsif type == 'Album'
      '<div class="l_album">'
    elsif type == 'Mix'
      '<div class="l_mix">'
    else
      '<div class="l_music">'
    end
  end
  
  def hidden_div_if(condition, attributes = {}, &block)
    if condition
      attributes["style"] = "display: none"
    end
    content_tag("div", attributes, &block)
  end
  
  def hidden_span_if(condition, attributes = {}, &block)
    if condition
      attributes["style"] = "display: none"
    end
    content_tag("span", attributes, &block)
  end
  
  def li_with_class_if(condition, attr, &block)
    attributes = {}
    if condition
      attributes["class"] = attr
    end
    content_tag('li', attributes, &block)
  end
  
  def link_to_show_depending_on_type(entry, text=nil, attr = {})
    text ||= h entry.name
    link_to( text, {:controller => entry.class.to_s.downcase.pluralize,
                         :action => 'show',
                         :id => entry}, attr )
  end
  
  def echo_name(entry)
    if entry
      h entry.name
    else
      '<em>unknown</em>'
    end
  end
  
  def link_to_name(entry)
    if entry
      link_to( (h entry.name), entry)
    else
      '<em>unknown</em>'
    end
  end
  
  def report_entry(entry)
    unless entry.report
      link_to 'Report Entry', new_music_report_path( entry )
    else
      'Reported Entry'
    end
  end
  
  def report_comment(comment)
    unless comment.report
      link_to 'Report Comment', {:controller => 'reports', :action => 'comment', :id => comment},
                                :method => :post,
                                :confirm => "Something is wrong with the comment? Report it to the administrator?"
                                
    else
      'Reported Comment'
    end
  end
  
  def show_time(time)
    if current_user && current_user.time_zone
      time.in_time_zone(current_user.time_zone).to_s(:long)
    else
      time.to_s(:long)
    end
  end
  
  def show_time_short(time)
    if current_user && current_user.time_zone
      time.in_time_zone(current_user.time_zone).strftime("%x")
    else
      time.strftime("%x")
    end
  end
  
  def inbox_link(user)
    no = Inbox.count(:conditions => ["reciever = ? AND messages.read = 0", user.id])
    link_to_unless_current no, inbox_index_path(user)
  end
  
  def invitations_link(user)
    link_to_unless_current no_invitations, myinvitations_path(current_user)
  end
  
  def no_invitations
    invitations = GroupInvitation.count(:all, :conditions => ["reciever = ?", current_user.id])
    project_invitations = ProjectMembership.count(:all, :conditions => ["user_id = ? AND status = 'invited'", current_user.id])
    admin_invitations = GroupAdminInvitation.count(:all, :conditions => ["reciever = ?", current_user.id])
    project_invitations + current_user.fans_of_me.length + invitations + admin_invitations
  end
  
  def new_mail?(user)
    no = Inbox.count(:conditions => ["reciever = ? AND messages.read = 0", user.id])
    if no > 0
      true
    else
      false
    end
  end
  
  def link_to_loving(item)
    p = pluralize item.favourites_count, 'person'
    if item.favourites_count > 1
      t = ' love this item'
    else
      t = ' loves this item'
    end
    link_to p + t,
                :controller => 'music',
                :action => 'favourized_by',
                :id => item
  end
  
  def format_text(text)
    text = RedCloth.new(text, [:filter_html]).to_html
    text.gsub!(/\:\)/, '<span class="smile">&nbsp;</span>')
    text.gsub!(/\;\)/, '<span class="wink">&nbsp;</span>')
    text.gsub!(/\:\(/, '<span class="sad">&nbsp;</span>')
    text.gsub!(/<a /, '<a target="_blank" rel="nofollow" ') unless text =~ /<a href="http:\/\/computer-beatz\.net.*/
    return text
  end
  
  def mailbox_status_ok?(user)
    count = Inbox.count(:all, :conditions => ["reciever = ?", user.id]) +
                   Outbox.count(:all, :conditions => ["sender = ?", user.id])
    return false if count > 490
    true
  end

  def switch_advert_right_div()
    #array of ["<css-class>", likelihood in %], last position is used as default
    switch = [["google_ads", 60], ["cb_advertise"]]
    tag = switch[-1][0]
    r = rand(100)
    for i in 0..(switch.size() -2) do
      if r < switch[i][1]
        tag = switch[i][0]
        break
      end
      r -= switch[i][1]
    end
    tag
  end
  
  def link_to_artist(item)
    if item.artist
      link_to (h item.artist.name), item.artist
    else
      link_to 'Set artist', {:action => 'add_artist', 
                               :id => item.id},
                               :class => 'add'
    end
  end
  
  def link_to_label(item)
    if item.label
      link_to (h item.label.name), item.label
    else
      link_to 'Set label', {:action => 'add_label',
                             :id => item.id},
                             :class => 'add'
    end
  end
  
  def echo_release_date(item)
    if item.release_date
      item.release_date.year.to_s
    else
      link_to 'enter release date', :action => 'enter_release_date',
                                    :id => item.id
    end
  end
  
  def user_menu_link( name, url, user, option )
    return name if current_page?( url )
    if show_user_item?(user, option)
      link_to name, url
    else
      '<span class="inactive" title="Is not shown to everyone">' + name + '</span>'
    end
  end
  
  def show_user_item?(user, option)
    if user == current_user
       return true
    elsif option == 'privat'
      return false
    elsif option == 'friends'
      return true if logged_in? && current_user.is_mutual_friends_with?(user)
      return false
    elsif option == 'users'
      return logged_in?
    elsif option == 'public'
      return true
    else
      false
    end
  end
  
  def user_has_hidden_info?(user)
    if user.motto_privacy == 'private' ||
       user.guestbook_privacy == 'private' ||
       user.groups_privacy  == 'private'||
       user.tagged_privacy == 'private' ||
       user.friendships_privacy == 'private' ||
       user.favourites_privacy == 'private'
         return true
    elsif logged_in? && !current_user.is_mutual_friends_with?(user) &&
       (user.motto_privacy == 'friends' ||
       user.guestbook_privacy == 'friends' ||
       user.groups_privacy  == 'friends'||
       user.tagged_privacy == 'friends' ||
       user.friendships_privacy == 'friends' ||
       user.favourites_privacy == 'friends')
         return true
    elsif !logged_in? &&
       (user.motto_privacy == 'users' ||
       user.guestbook_privacy == 'users' ||
       user.groups_privacy  == 'users' ||
       user.tagged_privacy == 'users' ||
       user.friendships_privacy == 'users' ||
       user.favourites_privacy == 'users')
         return true
    else
      false
    end
  end
  
  def show_creative_commons(project)
    res = case project.license
      when 'by' then 
        '<a rel="license" href="http://creativecommons.org/licenses/by/3.0/" target="_blank">
          <img alt="Creative Commons License" style="border-width:0" src="http://i.creativecommons.org/l/by/3.0/88x31.png"/>
        </a>'
      when 'by-sa' then
        '<a rel="license" href="http://creativecommons.org/licenses/by-sa/3.0/" target="_blank">
          <img alt="Creative Commons License" style="border-width:0" src="http://i.creativecommons.org/l/by-sa/3.0/88x31.png"/>
        </a>'
      when 'by-nd' then
        '<a rel="license" href="http://creativecommons.org/licenses/by-nd/3.0/" target="_blank">
          <img alt="Creative Commons License" style="border-width:0" src="http://i.creativecommons.org/l/by-nd/3.0/88x31.png"/>
        </a>'
      when 'by-nc' then
        '<a rel="license" href="http://creativecommons.org/licenses/by-nc/3.0/" target="_blank">
          <img alt="Creative Commons License" style="border-width:0" src="http://i.creativecommons.org/l/by-nc/3.0/88x31.png"/>
        </a>'
      when 'by-nc-sa' then
        '<a rel="license" href="http://creativecommons.org/licenses/by-nc-sa/3.0/" target="_blank">
          <img alt="Creative Commons License" style="border-width:0" src="http://i.creativecommons.org/l/by-nc-sa/3.0/88x31.png"/>
        </a>'
      when 'by-nc-nd' then
        '<a rel="license" href="http://creativecommons.org/licenses/by-nc-nd/3.0/" target="_blank">
          <img alt="Creative Commons License" style="border-width:0" src="http://i.creativecommons.org/l/by-nc-nd/3.0/88x31.png"/>
        </a>'
    end
    res
  end
  
end
