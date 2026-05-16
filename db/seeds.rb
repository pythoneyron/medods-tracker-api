Tag::SYSTEM_NAMES.each do |name|
  Tag.find_or_create_by!(name: name, system: true)
end