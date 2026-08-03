#!/usr/bin/env ruby

require "json"
require "open3"

project_root = File.expand_path("..", __dir__)
gallery_root = File.join(project_root, "assets", "gallery", "painting")
output_path = File.join(project_root, "painting-gallery-data.js")

groups = [
  ["figure", "figure", "figure"],
  ["flora", "foundations", "flora/foundations"],
  ["flora", "elementary", "flora/elementary"],
  ["flora", "intermediate", "flora/intermediate"],
  ["landscape", "foundations", "landscape/foundations"],
  ["landscape", "elementary", "landscape/elementary"],
  ["landscape", "intermediate", "landscape/intermediate"],
  ["studio", "freehand", "freehand"],
  ["studio", "sketch", "sketch"],
]

featured_order = {
  "flora/foundations" => %w[
    ChunFengSongNuan HuaKaiFuGui JinJiFuGui MengHuXiaShan
    MengHu SongHeYanNian huaniao1 huaniao2
  ],
  "landscape/foundations" => %w[
    YangZiRiver GreatWall-XiongGuanWanLi HuangShanYunHai
    JinBiShanShui GreatWall JinQiu XiaoQiaoLiuShui
  ],
  "freehand" => %w[
    DaXieYi-BaJiao DaXieYi-LanCao DaXieYi-SongShu-DaXieYi
    DaXieYi-HuLu-NanGua-DaXieYi DaXieYi-JuHua-DaXieYi
    DaXieYi-MoYeHeHua
  ],
  "sketch" => %w[bridge cat cherry sailboat],
}

def dimensions(path)
  output, status = Open3.capture2("sips", "-g", "pixelWidth", "-g", "pixelHeight", path)
  raise "Could not read dimensions for #{path}" unless status.success?

  width = output[/pixelWidth:\s+(\d+)/, 1]&.to_i
  height = output[/pixelHeight:\s+(\d+)/, 1]&.to_i
  raise "Missing dimensions for #{path}" unless width && height

  [width, height]
end

rooms = Hash.new { |hash, key| hash[key] = [] }

groups.each do |room, collection, relative_directory|
  directory = File.join(gallery_root, relative_directory)
  names = Dir.children(directory).select { |name| name.downcase.end_with?(".jpg") }
  preferred = featured_order.fetch(relative_directory, [])
  rank = preferred.each_with_index.to_h
  names.sort_by! do |name|
    base = File.basename(name, File.extname(name))
    [rank.fetch(base, preferred.length), base.downcase]
  end

  names.each do |name|
    absolute_path = File.join(directory, name)
    width, height = dimensions(absolute_path)
    rooms[room] << {
      "src" => "assets/gallery/painting/#{relative_directory}/#{name}",
      "key" => File.basename(name, File.extname(name)),
      "collection" => collection,
      "width" => width,
      "height" => height,
    }
  end
end

payload = JSON.pretty_generate(rooms)
File.write(output_path, "window.PAINTING_GALLERY = Object.freeze(#{payload});\n")

puts "Wrote #{rooms.values.sum(&:length)} works to #{output_path}."
