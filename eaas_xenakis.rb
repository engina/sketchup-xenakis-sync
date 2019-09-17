require 'sketchup.rb'
require 'extensions.rb'

module XenakisExtension
  unless file_loaded?(__FILE__)
    ex = SketchupExtension.new('Xenakis', 'eaas_xenakis/main.rb')
    ex.description = 'Sync your model with Xeankis Acoustic Analysis Tool'
    ex.version     = '1.0.0'
    ex.copyright   = 'EAAS © 2019'
    ex.creator     = 'EAAS'
    Sketchup.register_extension(ex, true)
    file_loaded(__FILE__)
  end
end
