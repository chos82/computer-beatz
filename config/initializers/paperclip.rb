Paperclip::Attachment.interpolations[:name] = proc do |attachment, style|
  attachment.instance.name.downcase.dasherize.parameterize
end