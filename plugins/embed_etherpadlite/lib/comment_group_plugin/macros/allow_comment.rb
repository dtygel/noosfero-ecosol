class CommentGroupPlugin::AllowComment < Noosfero::Plugin::Macro
  def self.configuration
    { :params => [],
      :skip_dialog => true,
      :generator => 'execEmbedEtherpadLite();',
      :js_files => 'comment_group.js',
      :icon_path => '/designs/icons/tango/Tango/16x16/emblems/emblem-system.png',
      :css_files => '' }
  end

end
