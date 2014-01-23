# An enterprise is a kind of organization. According to the system concept,
# only enterprises can offer products and services.
class Enterprise < Organization

  SEARCH_DISPLAYS += %w[map full]

  def self.type_name
    _('Enterprise')
  end

  N_('Enterprise')

  has_many :products, :foreign_key => :profile_id, :dependent => :destroy, :order => 'name ASC'
  has_many :inputs, :through => :products
  has_many :production_costs, :as => :owner

  has_and_belongs_to_many :fans, :class_name => 'Person', :join_table => 'favorite_enteprises_people'

  def product_categories
    products.includes(:product_category).map{|p| p.category_full_name}.compact
  end

  N_('Organization website'); N_('Historic and current context'); N_('Activities short description'); N_('City'); N_('State'); N_('Country'); N_('ZIP code')

  settings_items :organization_website, :historic_and_current_context, :activities_short_description, :zip_code, :city, :state, :country
  settings_items :products_per_catalog_page, :type => :integer, :default => 6

  extend SetProfileRegionFromCityState::ClassMethods
  set_profile_region_from_city_state

  before_save do |enterprise|
    enterprise.organization_website = enterprise.maybe_add_http(enterprise.organization_website)
  end
  include MaybeAddHttp

  def business_name
    self.nickname
  end
  def business_name=(value)
    self.nickname = value
  end
  N_('Business name')

  FIELDS = %w[
    business_name
    organization_website
    historic_and_current_context
    activities_short_description
    acronym
    foundation_year
  ]

  def self.fields
    super + FIELDS
  end

  def validate
    super
    self.required_fields.each do |field|
      if self.send(field).blank?
        self.errors.add_on_blank(field)
      end
    end
  end

  def active_fields
    environment ? environment.active_enterprise_fields : []
  end

  def highlighted_products_with_image(options = {})
    Product.find(:all, {:conditions => {:highlighted => true}, :joins => :image}.merge(options))
  end

  def required_fields
    environment ? environment.required_enterprise_fields : []
  end

  def signup_fields
    environment ? environment.signup_enterprise_fields : []
  end

  def closed?
    true
  end

  def blocked?
    data[:blocked]
  end

  def block
    data[:blocked] = true
    save
  end

  def unblock
    data[:blocked] = false
    save
  end

  def enable(owner)
    return if enabled
    affiliate owner, Profile::Roles.all_roles(environment.id) if owner
    update_attribute(:enabled,true)
    if environment.replace_enterprise_template_when_enable
      apply_template(template)
    end
    save_without_validation!
  end

  def question
    if !self.foundation_year.blank?
      :foundation_year
    elsif !self.cnpj.blank?
      :cnpj
    else
      nil
    end
  end

  after_create :create_activation_task
  def create_activation_task
    if !self.enabled
      EnterpriseActivation.create!(:enterprise => self, :code_length => 7)
    end
  end
  def activation_task
    self.tasks.where(:type => 'EnterpriseActivation').first
  end

  def default_set_of_blocks
    links = [
      {:name => _("Enterprises's profile"), :address => '/profile/{profile}', :icon => 'ok'},
      {:name => _('Blog'), :address => '/{profile}/blog', :icon => 'edit'},
      {:name => _('Products'), :address => '/catalog/{profile}', :icon => 'new'},
    ]
    blocks = [
      [MainBlock.new],
      [ ProfileImageBlock.new,
        LinkListBlock.new(:links => links),
        ProductCategoriesBlock.new
      ],
      [LocationBlock.new]
    ]
    if environment.enabled?('products_for_enterprises')
      blocks[2].unshift ProductsBlock.new
    end
    blocks
  end

  def default_set_of_articles
    [
      Blog.new(:name => _('Blog')),
    ]
  end

  before_create do |enterprise|
    enterprise.validated = enterprise.environment.enabled?('enterprises_are_validated_when_created')
    if enterprise.environment.enabled?('enterprises_are_disabled_when_created')
      enterprise.enabled = false
    end
    true
  end

  def default_template
    environment.enterprise_template
  end

  def template_with_inactive_enterprise
    !enabled? ? environment.inactive_enterprise_template : template_without_inactive_enterprise
  end
  alias_method_chain :template, :inactive_enterprise

  def control_panel_settings_button
    {:title => __('Enterprise Info and settings'), :icon => 'edit-profile-enterprise'}
  end

  settings_items :enable_contact_us, :type => :boolean, :default => true

  def enable_contact?
    enable_contact_us
  end

  def control_panel_settings_button
    {:title => __('Enterprise Info and settings'), :icon => 'edit-profile-enterprise'}
  end

  def create_product?
    true
  end

  def activities
    Scrap.find_by_sql("SELECT id, updated_at, 'Scrap' AS klass FROM scraps WHERE scraps.receiver_id = #{self.id} AND scraps.scrap_id IS NULL UNION SELECT id, updated_at, 'ActionTracker::Record' AS klass FROM action_tracker WHERE action_tracker.target_id = #{self.id} UNION SELECT action_tracker.id, action_tracker.updated_at, 'ActionTracker::Record' AS klass FROM action_tracker INNER JOIN articles ON action_tracker.target_id = articles.id WHERE articles.profile_id = #{self.id} AND action_tracker.target_type = 'Article' ORDER BY updated_at DESC")
  end

  def catalog_url
    { :profile => identifier, :controller => 'catalog'}
  end

  def more_recent_label
    ''
  end

end
