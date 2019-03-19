module TagsHelper
  # See the README for an example using tag_cloud.
  def tag_cloud(tags, classes = %w{ tagCloud1 tagCloud2 tagCloud3 tagCloud4 tagCloud5 })
    max_count = tags.sort_by(&:count).last.count.to_f
    
    tags.each do |tag|
      index = ((tag.count / max_count) * (classes.size - 1)).round
      yield tag, classes[index]
    end
  end
end