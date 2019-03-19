class StaticController < ApplicationController
  
  def docnoize
    redirect_to 'http://computer-beatz.net/docnoize/index.html'
  end
  
  def textile
    @page_title = 'Textile Markdown Reference'
  end
  
  def release_policy
    @page_title = 'Realease Policy'
  end
  
  def privacy_policy
    @page_title = 'Privacy Policy'
  end

  def terms
    @page_title = 'Terms of use'
  end
  
end
