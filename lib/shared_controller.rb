module Shared
  
  def find_latest_creations(lim)
    @latest = 'foo'
  end
  
  def set_page_counts(total, per_page)
    @total = total
    if params[:page]
      @from = (params[:page].to_i - 1) * per_page + 1
      if @total > params[:page].to_i * per_page
        @to = params[:page].to_i * per_page
      else
        @to = @total
      end
    else
      @from = @total != 0 ? 1 : 0
      if @total > per_page
        @to = per_page
      else
        @to = @total
      end      
    end
  end
  
  def syntax_checker(query)
    query.strip!
    query.gsub!(/\s+/, ' ')
    if query =~ /(^(\+|,|\|)|(\++|,+|\|+|#+)|(\+|,|\||#)$)|(\*)/ || query.blank?
      return false
    else
      return query
    end
  end
  
  def advanced_syntax_checker(query)
    query.strip!
    query.gsub!(/\s+/, ' ')
    if query =~ /^(\+|,|\|)|(\++|,+|\|+|#+)|(\+|,|\||#)$/
      return false
    else
      return query
    end
  end
  
end