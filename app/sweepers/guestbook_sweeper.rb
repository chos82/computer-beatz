class GuestbookSweeper < ActionController::Caching::Sweeper

  observe GuestbookEntry

  # If we create a new article, the public list of articles must be regenerated
  def after_create(gbe)#
    expire_show_user gbe
  end

  # Deleting a page means we update the public list and blow away the cached article
  def after_destroy(gbe)
    expire_show_user gbe
  end

  private

  def expire_show_user gbe
    expire_action(:controller => 'users',
                  :action => 'show')
    expire_action(:controller => 'users',
                  :action => 'myprofile')
  end

end
