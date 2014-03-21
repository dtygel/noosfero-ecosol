class Box < ActiveRecord::Base
  belongs_to :owner, :polymorphic => true
  acts_as_list :scope => 'owner_id = #{owner_id} and owner_type = \'#{owner_type}\''
  has_many :blocks, :dependent => :destroy, :order => 'position'

  include Noosfero::Plugin::HotSpot

  named_scope :with_position, :conditions => ['boxes.position > 0']

  def environment
    owner ? (owner.kind_of?(Environment) ? owner : owner.environment) : nil
  end

  def acceptable_blocks
    blocks_classes = central?  ? Box.acceptable_center_blocks + plugins.dispatch(:extra_blocks, :type => owner.class, :position => 1) : Box.acceptable_side_blocks + plugins.dispatch(:extra_blocks, :type => owner.class, :position => [2, 3])
    to_css_class_name(blocks_classes)
  end

  def central?
    position == 1
  end

  def self.acceptable_center_blocks
    [ ArticleBlock,
      BlogArchivesBlock,
      CategoriesBlock,
      CommunitiesBlock,
      EnterprisesBlock,
      EnvironmentStatisticsBlock,
      FansBlock,
      FavoriteEnterprisesBlock,
      FeedReaderBlock,
      FriendsBlock,
      HighlightsBlock,
      LinkListBlock,
      LoginBlock,
      MainBlock,
      MembersBlock,
      MyNetworkBlock,
      PeopleBlock,
      ProfileImageBlock,
      RawHTMLBlock,
      RecentDocumentsBlock,
      SellersSearchBlock,
      TagsBlock ]
  end

  def self.acceptable_side_blocks
    [ ArticleBlock,
      BlogArchivesBlock,
      CategoriesBlock,
      CommunitiesBlock,
      DisabledEnterpriseMessageBlock,
      EnterprisesBlock,
      EnvironmentStatisticsBlock,
      FansBlock,
      FavoriteEnterprisesBlock,
      FeaturedProductsBlock,
      FeedReaderBlock,
      FriendsBlock,
      HighlightsBlock,
      LinkListBlock,
      LocationBlock,
      LoginBlock,
      MembersBlock,
      MyNetworkBlock,
      PeopleBlock,
      ProductsBlock,
      ProductCategoriesBlock,
      ProfileImageBlock,
      ProfileInfoBlock,
      ProfileSearchBlock,
      RawHTMLBlock,
      RecentDocumentsBlock,
      SellersSearchBlock,
      SlideshowBlock,
      TagsBlock
    ]
  end

  private

  def to_css_class_name(blocks_classes)
    blocks_classes.map{ |block_class| block_class.name.to_css_class }
  end

end
