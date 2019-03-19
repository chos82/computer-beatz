module LabelsHelper
  
  def show_license(label)
    if label.license == 'free'
      return '<span class="free-license"></span>Free label'
    elsif label.license == 'commercial'
      return ' <span class="commercial-license"></span>Commercial label'
    else
      link_to( "Set License Status", set_license_label_path(label) )
    end
  end
  
end
