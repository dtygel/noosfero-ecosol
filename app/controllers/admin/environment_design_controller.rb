class EnvironmentDesignController < BoxOrganizerController
  
  protect 'edit_environment_design'

  def available_blocks
    @available_blocks ||= [ LoginBlock, EnvironmentStatisticsBlock, RecentDocumentsBlock, ProfileListBlock ]
  end

end
