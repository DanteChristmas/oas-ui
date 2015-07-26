module OasSchool
  module HeroHelper
    def get_hero(options={})
      # Set Default options
      options = hero_options options
      # Get Content options
      content_options = hero_content_options options

      result = []
      if options[:has_priority]
        #Get priority content if needed
        result = get_priority_hero content_options
        if result.length < options[:limit]
          #backfill if needed
          filter_ids = result.map{|i| i[:id]}
          result += get_hero_content content_options,filter_ids
        end
      else
        #just fill up the normal hero
        result = get_hero_content content_options
      end
      #only return the requested limit
      result.take options[:limit]
    end

    def hero_options(options)
      options[:content_types] = options[:content_types] || 'article,media'
      options[:limit] = options[:limit] || 5
      options[:has_priority] = options[:has_priority].present? ? options[:has_priority] : false
      options[:force] = options[:force].present? ? options[:force] : false
      options
    end

    def hero_content_options(options)
      content_options = {}
      if options[:content_types].include? 'article'
        content_options[:article] = {
          limit: options[:limit],
          sub_type: 'ARTICLE',
          sort: 'publishEnvelope.beginPublishDate',
          sort_direction: 'DESC',
          force: options[:force]
        }
        content_options[:article][:sport_codes] = options[:sport_codes] if options[:sport_codes]
      end
      if options[:content_types].include? 'media'
        content_options[:media] = {
          limit: options[:limit],
          media_type: 'video',
          sort: 'publishEnvelope.beginPublishDate',
          sort_direction: 'DESC',
          include: 'streams',
          force: options[:force]
        }
        content_options[:media][:sport_codes] = options[:sport_codes] if options[:sport_codes]
      end
      content_options
    end

    def get_hero_content(content_options, filter_ids=[])
      article_group = []
      media_group = []

      result = []
      if content_options[:article].present?
        content_options[:article][:limit] = content_options[:article][:limit] + 10
        article_group = OasApi::Article.all(content_options[:article])
        article_group.reject!{|a| a[:largeImage].nil?}
        result += article_group
      end
      if content_options[:media].present?
        content_options[:media][:limit] = content_options[:media][:limit] + 10
        media_group = OasApi::Media.all(content_options[:media])
        media_group.reject!{|a| a[:largeImage].nil?}
        result += media_group
      end

      if filter_ids.present?
        result = OasApi::MapperUtils.filter_ids_out_of_collection(filter_ids, result)
      end
      result.sort_by! {|item| item[:published]}
      result.reverse!
    end

    def get_priority_hero(options)
      article_priority = []
      media_priority = []

      if options[:article].present?
        article_opts = options[:article].clone
        article_opts[:tags] = Rails.configuration.hero_priority_tag
        article_opts[:create_date_minus_days] = 3
        article_priority = OasApi::Article.all(article_opts)
      end
      if options[:media].present?
        media_opts = options[:media].clone
        media_opts[:tags] = Rails.configuration.hero_priority_tag
        media_opts[:create_date_minus_days] = 3
        media_priority = OasApi::Media.all(media_opts)
      end
      result = article_priority + media_priority
      result.reject!{|a| a[:largeImage].nil?}
      sort_by_priority(result)
    end

    def sort_by_priority(group)
      priority_1 = []
      priority_2 = []

      group.each do |i|
        i[:tags].each do |t|
          if t[:code] === 'customsystag_hero_priority_1'
            priority_1 << i
          end

          if t[:code] === 'customsystag_hero_priority_2'
            priority_2 << i
          end
        end
      end
      group = priority_1 + priority_2
      group.uniq{|m| m[:id]}
    end
  end
end
