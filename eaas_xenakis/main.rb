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
    toolbar = UI::Toolbar.new "Xenakis"
    cmd = UI::Command.new("Sync") {
      self.sync
    }
    if RUBY_PLATFORM.include? 'darwin'
      cmd.large_icon = "logo.pdf"
    elsif RUBY_PLATFORM.include? 'mingw'
      cmd.large_icon = "logo.svg"
    end
    cmd.tooltip = "Sync with Xenakis"
    cmd.status_bar_text = "Sync with Xenakis Acoustic Analysis Tool"
    cmd.menu_text = "Test"
    toolbar = toolbar.add_item cmd
    toolbar.show
    file_loaded(__FILE__)
  end
end
