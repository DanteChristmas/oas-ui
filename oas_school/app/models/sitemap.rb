# require 'sitemap_generator'
# require 'rufus-scheduler'
# require 'nunes'
# require 'statsd'
module OasSchool
  class Sitemap
    def self.startup
      if Rails.configuration.should_generate_sitemap
        scheduler = Rufus::Scheduler.new
        scheduler.schedule_in('5s') do
          self.generate
          scheduler.every "#{Rails.configuration.sitemap_generation_interval}" do
            self.generate
          end
        end
      end
    end

    def self.generate
      Rails.logger.debug 'Generating Sitemap'
      # start_time = Time.now

      $statsd.time('sitemap.generation') do
        sitemap_item_length = Rails.configuration.sitemap_item_length

        sports = OasApi::S3Models::Sport.sports
        schools = OasApi::S3Models::School.schools
        shows = OasApi::Show.all

        SitemapGenerator::Sitemap.create_index = true
        SitemapGenerator::Sitemap.default_host = "http://#{Rails.configuration.my_hostname}"
        SitemapGenerator::Sitemap.create do
          group(:filename => :general) do
            add '/', :changefreq => 'daily', :priority => 0.9
            add '/videos/', :changefreq => 'hourly', :priority => 0.9
            add '/schedule-list/', :changefreq => 'hourly', :priority => 0.9
            add '/news/', :changefreq => 'hourly', :priority => 0.9
            add '/stats/', :changefreq => 'hourly', :priority => 0.9
            add '/standings/', :changefreq => 'hourly', :priority => 0.9

            # Sport Pages
            sports.try(:each) do | sport |
              sport_code = sport.try(:[], :sportCode)
              add "/sport/#{sport_code}", :changefreq => 'hourly', :priority => 0.9
            end
            # School Pages
            schools.try(:each) do | school |
              school_code = school.try(:[], :schoolCode)
              add "/school/#{school_code}", :changefreq => 'hourly', :priority => 0.9
            end
            # Sport-Specific Video Pages
            sports.try(:each) do | sport |
              sport_code = sport.try(:[], 'sportCode')
              add "/video/#{sport_code}", :changefreq => 'hourly', :priority => 0.9
            end
            # School-Specific Video Pages
            schools.try(:each) do | school |
              school_code = school.try(:[], :schoolCode)
              add "/video/#{school_code}", :changefreq => 'hourly', :priority => 0.9
            end

            shows.try(:each) do | show |
              url = show.try(:[], :url)
              add "#{url}", :changefreq => 'daily', :priority => 0.9 if url
            end

          end

          group(:filename => :videos) do
            Sitemap.fetch_media_for_sitemap.try(:each) do | video |
              source_id=video.dto.try(:[], 'sourceInfos').try(:first).try(:[], 'sourceId')

              add("/video/#{video.id}", :video => {
                :thumbnail_loc => "#{video.image_url(OasApi.configuration.imgix_config[:thumbnail])}",
                :title => "#{video.name}",
                :description => "#{video.description}",
                :player_loc => "https://player.ooyala.com/tframe.html?embedCode=#{source_id}&pbid=#{Rails.configuration.ooyala_video_player_id}",
                :tags => SeoUtils.keywords_for_video(video.try(:map)),
                :publication_date => "#{video.published_date.try(:to_time).try(:iso8601)}"
              })
            end
          end

          group(:filename => :news) do
            Sitemap.fetch_news_for_sitemap.try(:each) do | article |
              add("/news/#{article.slug}", :news => {
                :publication_name => "#{Rails.configuration.publication_name}",
                :publication_language => "en",
                :title => "#{article.headline}",
                :keywords => "#{SeoUtils.keywords_for_article(article.map)}",
                :publication_date => "#{article.published.try(:to_time).try(:iso8601)}"
              })
            end
          end

          group(:filename => :custom_pages) do
            Sitemap.fetch_custom_pages_for_sitemap.try(:each) do | custom_page |
              add "/page/#{custom_page.slug}", :changefreq => 'weekly', :priority => 0.9
            end
          end

          group(:filename => :events) do
            Sitemap.fetch_events_for_sitemap.try(:each) do | event |
              add "/game-center/#{event.id}", :changefreq => 'daily', :priority => 0.9, :lastmod => event.last_modified_date.try(:to_time).try(:iso8601)
            end
          end
        end

        if Rails.configuration.ping_search_engines
          SitemapGenerator::Sitemap.ping_search_engines # Not needed if you use the rake tasks
        end
      end
    end

    def self.fetch_custom_pages_for_sitemap
      sitemap_item_length = self.sitemap_item_length
      sitemap_page_size = self.sitemap_page_size
      page_size = [sitemap_page_size, sitemap_item_length].min
      options = {
        page: 1,
        limit: page_size,
        sort_direction:'ASC',
        sub_type: 'CUSTOM_PAGE',
        raw: true
      }
      results = Array.new
      while results.length < sitemap_item_length
        custom_pages = OasApi::Article.all(options)
        custom_pages.each {|cp|results.push cp}

        break if custom_pages.last_page || results.length >= sitemap_item_length
        options[:page] = options[:page]+1
      end

      results
    end

    def self.fetch_media_for_sitemap
      sitemap_item_length = self.sitemap_item_length
      sitemap_page_size = self.sitemap_page_size
      page_size = [sitemap_page_size, sitemap_item_length].min
      options = {
        page: 1,
        limit: page_size,
        sort_direction:'ASC',
        raw: true
      }
      results = Array.new
      while results.length < sitemap_item_length
        videos = OasApi::Media.all(options)
        videos.each {|v|results.push v}

        break if videos.last_page || results.length >= sitemap_item_length
        options[:page] = options[:page]+1
      end

      results
    end

    def self.fetch_events_for_sitemap
      sitemap_item_length = self.sitemap_item_length
      sitemap_page_size = self.sitemap_page_size
      page_size = [sitemap_page_size, sitemap_item_length].min
      options = {
        page: 1,
        limit: page_size,
        sort_direction:'ASC',
        raw: true
      }
      results = Array.new
      while results.length < sitemap_item_length
        events = OasApi::Event.all(options)
        events.each {|e|results.push e}

        break if events.last_page || results.length >= sitemap_item_length
        options[:page] = options[:page]+1
      end

      results
    end

    def self.fetch_news_for_sitemap
      sitemap_item_length = self.sitemap_item_length
      sitemap_page_size = self.sitemap_page_size
      page_size = [sitemap_page_size, sitemap_item_length].min
      options = {
        page: 1,
        limit: page_size,
        sort_direction:'ASC',
        sub_type: 'ARTICLE',
        raw: true
      }
      results = Array.new
      while results.length < sitemap_item_length
        articles = OasApi::Article.all(options)
        articles.each {|a|results.push a}

        break if articles.last_page || results.length >= sitemap_item_length
        options[:page] = options[:page]+1
      end

      results
    end

    def self.sitemap_item_length
      @sitemap_item_length ||= Rails.configuration.try(:sitemap_item_length) || 5000
    end

    def self.sitemap_page_size
      @sitemap_page_size ||= Rails.configuration.try(:sitemap_page_size) || 500
    end


  end
end
