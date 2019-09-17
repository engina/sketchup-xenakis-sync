require 'sketchup.rb'

module XenakisExtension
  PRECISION = 6

  def self.sync
    modelexport = {
      "version" => 3,
      "signature" => "XAAT",
      "surfaces" => [],
      "receivers" => [],
      "sources" => [],
    }

    Sketchup.active_model.entities.grep(Sketchup::Face)
    .find_all {|f| f.hidden? === false}.each do |face|
      material = face.layer.name
      mesh = face.mesh
      surface = {
        "material" => material,
        "vertices" => [],
        "faces" => [],
      }
      
      mesh.points.each do |point|
        surface["vertices"] << [point.x.to_m.round(PRECISION), point.y.to_m.round(PRECISION), point.z.to_m.round(PRECISION)]
      end
      
      mesh.polygons.each do |poly|
        surface["faces"] << [poly[0].abs - 1, poly[1].abs - 1, poly[2].abs - 1]
      end
      modelexport["surfaces"] << surface
    end

    # NAME SHOULD BE CHECKED FOR RECEIVER AND SOURCES?
    Sketchup.active_model.entities.grep(Sketchup::ComponentInstance)
    .find_all {|e| e.definition.name === "Receiver" and e.hidden? === false}.each do |r|
      receiver = {
        "name" => r.name,
        "position" => [],
        "attributes" => {}
      }
      c = r.bounds.center
      receiver["position"] = [c.x.to_m.round(PRECISION), c.y.to_m.round(PRECISION), c.z.to_m.round(PRECISION)]
      if r.attribute_dictionaries["dynamic_attributes"]
        r.attribute_dictionaries["dynamic_attributes"].each_pair do |key, val|
          if !key.start_with?("_")
            # if this is a length, we should convert it from inches
            receiver["attributes"][key] = val
          end
        end
      end
      modelexport["receivers"] << receiver
    end

    Sketchup.active_model.entities.grep(Sketchup::ComponentInstance)
    .find_all {|e| e.definition.name === "Source" and e.hidden? === false}.each do |s|
      source = {
        "name" => s.name,
        "position" => [],
        "attributes" => {}
      }
      c = s.bounds.center
      source["position"] = [c.x.to_m.round(PRECISION), c.y.to_m.round(PRECISION), c.z.to_m.round(PRECISION)]
      if s.attribute_dictionaries["dynamic_attributes"]
        s.attribute_dictionaries["dynamic_attributes"].each_pair do |key, val|
          if !key.start_with?("_")
            # if this is a length, we should convert it from inches
            source["attributes"][key] = val
          end
        end
      end
      modelexport["sources"] << source
    end
    self.cp2clip('###EAAS$$$' + DateTime.now.strftime('%Q').to_s + JSON.generate(modelexport))
  end

  def self.cp2clip(input)
    cmd = ''
    if RUBY_PLATFORM.include? 'darwin'
      cmd = 'pbcopy'
    elsif RUBY_PLATFORM.include? 'mingw'
      cmd = 'clip'
    end
    str = input.to_s
    IO.popen(cmd, 'w') { |f| f << str }
    str
  end
  
  unless file_loaded?(__FILE__)
    FILENAMESPACE = File.basename( __FILE__, '.rb' )
    PATH_ROOT     = File.dirname( __FILE__ ).freeze
    PATH          = File.join( PATH_ROOT, FILENAMESPACE ).freeze
    puts PATH_ROOT
    toolbar = UI::Toolbar.new "Xenakis"
    syncCmd = UI::Command.new("Sync") {
      self.sync
    }
    addReceiverCmd = UI::Command.new("Add Receiver") {
      Sketchup.active_model.import(File.join(PATH_ROOT, 'Receiver.skp'))
    }
    addSourceCmd = UI::Command.new("Add Source") {
      Sketchup.active_model.import(File.join(PATH_ROOT, 'Source.skp'))
    }
    if RUBY_PLATFORM.include? 'darwin'
      syncCmd.small_icon = syncCmd.large_icon = "logo.pdf"
      addSourceCmd.small_icon = addSourceCmd.large_icon = "Source.pdf"
      addReceiverCmd.small_icon = addReceiverCmd.large_icon = "Receiver.pdf"
    elsif RUBY_PLATFORM.include? 'mingw'
      cmd2.large_icon = cmd3.large_icon = syncCmd.large_icon = "logo.svg"
    end
    syncCmd.tooltip = "Sync with Xenakis"
    syncCmd.status_bar_text = "Sync with Xenakis Acoustic Analysis Tool"
    syncCmd.menu_text = "Test"

    addReceiverCmd.status_bar_text = addReceiverCmd.menu_text = addReceiverCmd.tooltip = "Add receiver"
    addSourceCmd.menu_text = addSourceCmd.status_bar_text = addSourceCmd.tooltip = "Add source"

    toolbar = toolbar.add_item syncCmd
    toolbar = toolbar.add_item addSourceCmd
    toolbar = toolbar.add_item addReceiverCmd
    toolbar.show
    file_loaded(__FILE__)
  end
end
