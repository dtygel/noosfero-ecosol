function execEmbedEtherpadLite() {
  tinyMCE.activeEditor.focus();
  start = jQuery(tinyMCE.activeEditor.selection.getStart()).closest('p');
  end = jQuery(tinyMCE.activeEditor.selection.getEnd()).closest('p');

  var padName = padPrefix + '.' + randomPadName();
  var iframe = "<iframe name='embed_readwrite' src='" + padUrl + padName + "?showControls=true&showChat=true&&alwaysShowChat=true&lang=pt&showLineNumbers=true&useMonospaceFont=false' width='" + padWidth + "' height='" + padHeight + "'></iframe>";
  ed.execCommand('mceInsertContent', false, iframe);
}

