module ReleasesHelper
  
  def link_to_loving_release(item)
    p = pluralize item.favourites_count, 'person'
    if item.favourites_count > 1
      t = ' love this item'
    else
      t = ' loves this item'
    end
    link_to( p + t, favourized_by_release_url(item) )
  end
  
  
end
