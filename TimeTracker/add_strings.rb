require 'xcodeproj'

project_path = './TimeTracker.xcodeproj'
project = Xcodeproj::Project.open(project_path)

# Main app target
app_target = project.targets.find { |t| t.name == 'TimeTracker' }

# Find or create group
group = project.main_group.find_subpath(File.join('TimeTracker', 'Resources'), true)
group.set_source_tree('<group>')

# Add the file to the project
file_path = 'TimeTracker/Localizable.xcstrings'
unless File.exist?(file_path)
  File.write(file_path, '{}')
end

# Check if it already exists in the project
file_ref = group.files.find { |f| f.path == 'Localizable.xcstrings' }
if file_ref.nil?
  file_ref = group.new_file('Localizable.xcstrings')
end

# Ensure it's added to the target
unless app_target.resources_build_phase.files_references.include?(file_ref)
  app_target.resources_build_phase.add_file_reference(file_ref)
end

project.save
puts "Added Localizable.xcstrings to project."
