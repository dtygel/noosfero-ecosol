class MainBlock < Block

  def self.description
    _('Main content')
  end

  def help
    _('This block presents the main content of your pages.')
  end

  def content(args={})
    nil
  end

  def main?
    true
  end

  def editable?
    true
  end

  def cacheable?
    false
  end

  def display_options
    ['always', 'except_home_page']
  end

end
