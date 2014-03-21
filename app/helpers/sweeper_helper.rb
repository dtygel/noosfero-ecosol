module SweeperHelper

  def expire_fragment(*args)
    ActionController::Base.new().expire_fragment(*args)
  end

  alias :expire_timeout_fragment :expire_fragment

  def expire_friends(profile)
    # public friends page
    pages =  profile.friends.count / Noosfero::Constants::PROFILE_PER_PAGE + 1
    (1..pages).each do |i|
      expire_timeout_fragment(profile.friends_cache_key(:npage => i.to_s))
    end
    # manage friends page
    pages =  profile.friends.count / Noosfero::Constants::PROFILE_PER_PAGE + 1
    (1..pages).each do |i|
      expire_timeout_fragment(profile.manage_friends_cache_key(:npage => i.to_s))
    end

    #not tested yet
    # friends blocks
    blocks = profile.blocks.select{|b| b.kind_of?(FriendsBlock)}
    expire_profile_blocks(blocks)
  end

  def expire_communities(profile)
    # public communities page
    pages =  profile.communities.count / Noosfero::Constants::PROFILE_PER_PAGE + 1
    (1..pages).each do |i|
      expire_timeout_fragment(profile.communities_cache_key(:npage => i.to_s))
    end

    # communities block
    blocks = profile.blocks.select{|b| b.kind_of?(CommunitiesBlock)}
    expire_profile_blocks(blocks)
  end

  def expire_enterprises(profile)
    # enterprises and favorite enterprises blocks
    blocks = profile.blocks.select {|b| [EnterprisesBlock, FavoriteEnterprisesBlock].any?{|klass| b.kind_of?(klass)} }
    expire_profile_blocks(blocks)
  end

  def expire_profile_index(profile)
    expire_timeout_fragment(profile.relationships_cache_key)
  end

  def expire_profile_blocks(blocks)
    blocks.each do |block|
      return if !block.environment
      regex = '-[a-z]*$'
      clean_ck = block.cache_key.gsub(/#{regex}/,'')
      block.environment.locales.keys.each do |locale|
        expire_timeout_fragment("#{clean_ck}-#{locale}")
      end
    end
  end

  def expire_blocks_cache(context, causes)
    if context.kind_of?(Profile)
      profile = context
      environment = profile.environment
    else
      environment = context
      profile = nil
    end

    blocks_to_expire = []
    if profile
      profile.blocks.each {|block|
        conditions = block.class.expire_on
        blocks_to_expire << block unless (conditions[:profile] & causes).empty?
      }
    end
    environment.blocks.each {|block|
      conditions = block.class.expire_on
      blocks_to_expire << block unless (conditions[:environment] & causes).empty?
    }

    blocks_to_expire.uniq!
    BlockSweeper.expire_blocks(blocks_to_expire)
  end

end
