module OasSchool
  module HomeHelper
    #Network wall that isn't allowed to replicate data from zee
    #Superhero
    def get_network_list(size=9, filter_ids=[], force=false)
      result = OasApi::Media.all({
        limit: 14,
        media_type: 'video',
        sort: 'publishEnvelope.beginPublishDate',
        sort_direction: 'DESC',
        sources: 'ooyala',
        sub_types: 'VideoObject,AudioObject',
        include: 'streams',
        labels: Rails.configuration.videodn_label,
        force: force
      })
      result = OasApi::MapperUtils.filter_ids_out_of_collection(filter_ids, result)
      result.take(size)
    end

    def get_content_wall(options={}, filter_ids=[], force=false)
      options[:limit] = options[:limit] || 10
      content_types = options[:content_types] || 'social,media,articles'
      options[:force] = force
      content_types = content_types.split(',')
      options[:alias] = 'ALL_SPORTS'
      result = []

      if content_types.include?('social')
        result.<< OasApi::Social::Post.all(options)
      end

      if content_types.include?('media')
        media_content = OasApi::Media.all({
          limit: options[:limit] + 5,
          media_type: 'video',
          sort: 'publishEnvelope.beginPublishDate',
          sort_direction: 'DESC',
          include: 'streams',
          force: force
        })
        result.<< media_content
      end

      if content_types.include?('articles')
        article_content = OasApi::Article.all({
          limit: options[:limit] + 5,
          sort: 'publishEnvelope.beginPublishDate',
          sort_direction: 'DESC',
          sub_type: 'ARTICLE',
          force: force
        })
        result.<< article_content
      end

      OasApi::MapperUtils.shuffle_media_together(result, options[:limit])
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
