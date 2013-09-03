class CommentGroupPlugin < Noosfero::Plugin

  def self.plugin_name
    "Comment Group"
  end

  def self.plugin_description
    _("A plugin that embeds a collaborative textpad.")
  end

  def js_files
    'embed_etherpadlite_macro.js'
  end

end

require_dependency 'embed_etherpadlite_plugin/macros/execEmbedEtherpadLite'
