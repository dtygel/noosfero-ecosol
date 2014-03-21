class Block < ActiveRecord::Base

  # to be able to generate HTML
  include ActionView::Helpers::UrlHelper
  include ActionView::Helpers::TagHelper

  # Block-specific stuff
  include BlockHelper

  delegate :environment, :to => :box, :allow_nil => true

  acts_as_list :scope => :box
  belongs_to :box

  acts_as_having_settings

  named_scope :enabled, :conditions => { :enabled => true }

  # Determines whether a given block must be visible. Optionally a
  # <tt>context</tt> must be specified. <tt>context</tt> must be a hash, and
  # may contain the following keys:
  #
  # * <tt>:article</tt>: the article being viewed currently
  # * <tt>:language</tt>: in which language the block will be displayed
  def visible?(context = nil)
    if display == 'never'
      return false
    end
    if context
      if language != 'all' && language != context[:locale]
        return false
      end
      if display == 'home_page_only'
        if context[:article]
          return context[:article] == owner.home_page
        else
          return context[:request_path] == '/'
        end
      elsif display == 'except_home_page'
        if context[:article]
          return context[:article] != owner.home_page
        else
          return context[:request_path] != '/' + (owner.kind_of?(Profile) ? owner.identifier : '')
        end
      end
    end
    true
  end

  # The condition for displaying a block. It can assume the following values:
  #
  # * <tt>'always'</tt>: the block is always displayed
  # * <tt>'never'</tt>: the block is hidden (it does not appear for visitors)
  # * <tt>'home_page_only'</tt> the block is displayed only when viewing the
  #   homepage of its owner.
  # * <tt>'except_home_page'</tt> the block is displayed only when viewing
  #   the homepage of its owner.
  settings_items :display, :type => :string, :default => 'always'

  # The block can be configured to be displayed in all languages or in just one language. It can assume any locale of the environment:
  #
  # * <tt>'all'</tt>: the block is always displayed
  settings_items :language, :type => :string, :default => 'all'

  # returns the description of the block, used when the user sees a list of
  # blocks to choose one to include in the design.
  #
  # Must be redefined in subclasses to match the description of each block
  # type. 
  def self.description
    '(dummy)'
  end

  # Returns the content to be used for this block.
  #
  # This method can return several types of objects:
  #
  # * <tt>String</tt>: if the string starts with <tt>http://</tt> or <tt>https://</tt>, then it is assumed to be address of an IFRAME. Otherwise it's is used as regular HTML.
  # * <tt>Hash</tt>: the hash is used to build an URL that is used as the address for a IFRAME. 
  # * <tt>Proc</tt>: the Proc is evaluated in the scope of BoxesHelper. The
  # block can then use <tt>render</tt>, <tt>link_to</tt>, etc.
  #
  # The method can also return <tt>nil</tt>, which means "no content".
  #
  # See BoxesHelper#extract_block_content for implementation details. 
  def content(args={})
    "This is block number %d" % self.id
  end

  # A footer to be appended to the end of the block. Returns <tt>nil</tt>.
  #
  # Override in your subclasses. You can return the same types supported by
  # #content.
  def footer
    nil
  end

  # Is this block editable? (Default to <tt>false</tt>)
  def editable?
    true
  end

  # must always return false, except on MainBlock clas.
  def main?
    false
  end

  def owner
    box ? box.owner : nil
  end

  def default_title
    ''
  end

  def title
    if self[:title].blank?
      self.default_title
    else
      self[:title]
    end
  end

  def view_title
    title
  end

  def cacheable?
    true
  end

  alias :active_record_cache_key :cache_key
  def cache_key(language='en')
    active_record_cache_key+'-'+language
  end

  def timeout
    4.hours
  end

  def has_macro?
    false
  end

  # Override in your subclasses.
  # Define which events and context should cause the block cache to expire
  # Possible events are: :article, :profile, :friendship, :category
  # Possible contexts are: :profile, :environment
  def self.expire_on
    {
      :profile => [],
      :environment => []
    }
  end

  DISPLAY_OPTIONS = {
    'always'           => __('In all pages'),
    'home_page_only'   => __('Only in the homepage'),
    'except_home_page' => __('In all pages, except in the homepage'),
    'never'            => __('Don\'t display'),
  }

  def display_options
    DISPLAY_OPTIONS.keys
  end

  def display_option_label(option)
    DISPLAY_OPTIONS[option]
  end

end
