module Helpers
  def google_analytics_account_id
    nil
  end
  
  def site_name
    "Thin - The high performance Ruby server"
  end
  
  def title
    @title || page.title
  end
  
  def description
    @description || title
  end
end