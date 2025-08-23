#!/usr/bin/env ruby

require 'xcodeproj'

# Open the project
project_path = '/Users/sou/Documents/AI_Driven_Dev/KOEMO/ios/KOEMO.xcodeproj'
project = Xcodeproj::Project.open(project_path)

# Get the main target
target = project.targets.first

# Get the main group
main_group = project.main_group

# Find or create Services group
services_group = main_group.find_subpath('KOEMO/Services') || main_group.find_subpath('KOEMO').new_group('Services')

# Services files to add
services_files = [
  'WebRTCService.swift',
  'APIService.swift',
  'AuthService.swift',
  'CallService.swift',
  'MatchingService.swift',
  'WebSocketService.swift'
]

services_files.each do |filename|
  file_path = "/Users/sou/Documents/AI_Driven_Dev/KOEMO/ios/KOEMO/Services/#{filename}"
  
  if File.exist?(file_path)
    # Check if file is already in project
    existing_file = services_group.children.find { |child| child.path == filename }
    
    unless existing_file
      puts "Adding #{filename} to project..."
      
      # Add file reference
      file_ref = services_group.new_reference(file_path)
      
      # Add to target
      target.add_file_references([file_ref])
      
      puts "✅ Added #{filename}"
    else
      puts "⚠️  #{filename} already in project"
    end
  else
    puts "❌ File not found: #{file_path}"
  end
end

# Save the project
project.save

puts "🎉 Project updated successfully!"