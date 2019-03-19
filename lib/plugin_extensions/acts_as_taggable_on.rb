module ActsAsTaggableOnFindTaggersExtension
   def find_taggers_for(*args)
      options = find_options_for_find_taggers_for(*args)
      options.blank? ? [] : find(:all,options)
    end

    def find_options_for_find_taggers_for(tags, taggable, options = {})
      tags = tags.is_a?(Array) ? TagList.new(tags.map(&:to_s)) : TagList.from(tags)

      return {} if tags.empty?

      conditions = []
      conditions << sanitize_sql(options.delete(:conditions)) if options[:conditions]

      unless (on = options.delete(:on)).nil?
        conditions << sanitize_sql(["context = ?",on.to_s])
      end

      taggings_alias, tags_alias = "#{table_name}_taggings", "#{table_name}_tags"

      conditions << tags.map { |t| sanitize_sql(["#{tags_alias}.name LIKE ?", t]) }.join(" OR ")

      conditions << sanitize_sql(["#{taggings_alias}.taggable_id = #{taggable.id} AND #{taggings_alias}.taggable_type = '#{taggable.class.base_class.to_s}'"])

      { :select => "DISTINCT #{table_name}.*",
        :joins => "LEFT OUTER JOIN #{Tagging.table_name} #{taggings_alias} ON #{taggings_alias}.tagger_id = #{table_name}.#{primary_key} AND #{taggings_alias}.tagger_type = #{quote_value(base_class.name)} " +
                  "LEFT OUTER JOIN #{Tag.table_name} #{tags_alias} ON #{tags_alias}.id = #{taggings_alias}.tag_id",
        :conditions => conditions.join(" AND ")
      }.update(options)
    end
end

module ActsAsTaggableOnFindTaggedByExtension
    def find_tagged_by(*args)
      options = find_options_for_find_tagged_by(*args)
      options.blank? ? [] : find(:all,options)
    end

    def find_options_for_find_tagged_by(tagger, options = {}, tags = nil)
      tags = tags.is_a?(Array) ? TagList.new(tags.map(&:to_s)) : TagList.from(tags)

      #return {} if tags.empty?

      conditions = []
      conditions << sanitize_sql(options.delete(:conditions)) if options[:conditions]

      unless (on = options.delete(:on)).nil?
        conditions << sanitize_sql(["context = ?",on.to_s])
      end

      taggings_alias, tags_alias = "#{table_name}_taggings", "#{table_name}_tags"

      conditions << tags.map { |t| sanitize_sql(["#{tags_alias}.name LIKE ?", t]) }.join(" OR ") unless tags.empty?

      conditions << sanitize_sql(["#{taggings_alias}.tagger_id = #{tagger.id} AND #{taggings_alias}.tagger_type = '#{tagger.class.to_s}'"])

      { :select => "DISTINCT #{table_name}.*, first_time_tagged",
        :joins => "LEFT OUTER JOIN #{Tagging.table_name} #{taggings_alias} ON #{taggings_alias}.taggable_id = #{table_name}.#{primary_key} AND #{taggings_alias}.taggable_type = #{quote_value(base_class.name)} " +
                  "LEFT OUTER JOIN #{Tag.table_name} #{tags_alias} ON #{tags_alias}.id = #{taggings_alias}.tag_id " + 
                  "LEFT OUTER JOIN (SELECT MIN( #{Tagging.table_name}.created_at ) AS first_time_tagged, taggable.id AS t_id FROM #{Tagging.table_name} " +
                                                "LEFT OUTER JOIN #{table_name} AS taggable ON #{Tagging.table_name}.taggable_id = taggable.id " +
                                   "GROUP BY taggable.id) get_first_tagging ON #{table_name}.id = get_first_tagging.t_id",
        :conditions => conditions.join(" AND ")
      }.update(options)
    end
end

module ActiveRecord
  module Acts
    module Tagger
      module SingletonMethods
        include ActsAsTaggableOnFindTaggersExtension
      end
    end
  end
end

module ActiveRecord
  module Acts
    module TaggableOn
      module InstanceMethods
        def save_tags
          (custom_contexts + self.class.tag_types.map(&:to_s)).each do |tag_type|
            next unless instance_variable_get("@#{tag_type.singularize}_list")
            owner = instance_variable_get("@#{tag_type.singularize}_list").owner
            new_tag_names = instance_variable_get("@#{tag_type.singularize}_list") - tags_on(tag_type, owner).map(&:name)
            old_tags = tags_on(tag_type, owner).reject { |tag| instance_variable_get("@#{tag_type.singularize}_list").include?(tag.name) }

            self.class.transaction do
              base_tags.delete(*old_tags) if old_tags.any?
              new_tag_names.each do |new_tag_name|
                new_tag = Tag.find_or_create_with_like_by_name(new_tag_name)
                Tagging.create(:tag_id => new_tag.id, :context => tag_type,
                               :taggable => self, :tagger => owner)
              end
            end
          end

          true
        end
      end
      module SingletonMethods
        include ActsAsTaggableOnFindTaggedByExtension
      end
    end
  end
end
