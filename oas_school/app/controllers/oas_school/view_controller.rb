# require 'oas'
module OasSchool
  class ViewController < OasSchool::ApplicationController
    before_action :populate_models
    helper_method :home?, :sport?

    def render *args
      populate_metadata
      set_global_copyright
      super
    end

    def page_not_found
      @not_found = true
      respond_to do |format|
        format.html { render template: 'errors/not_found_error', layout: 'layouts/application', status: 404 }
        format.json { render nothing: true, status: 404 }
        format.all  { render nothing: true, status: 404 }
      end
    end

    def not_found_title
      "#{Rails.configuration.publication_name} | Page Not Found"
    end

    #
    # Populates the models
    #
    def populate_models
      @kill_paywall = false #params[:paywall_toggle] == "false" ? false : true

      # TODO OAS-4354 - use the real popular links:
      @hostname = Rails.configuration.try(:my_hostname)
      @not_found = false
      @view_name = nil

      @selected_sport = params['sport_codes']
      @sport_subnav = OasApi::S3Models::SportSubnav.sport_subnav(@selected_sport)
      @navigation_hash = OasApi::S3Models::NavMenu.instance.all
      @promotions = OasApi::S3Models::Promotions.page(request.fullpath)
      @live_events = OasApi::Event.all({
        limit: 30,
        sort_direction: 'ASC',
        sort: 'eventDate',
        sub_types: 'SportEvent,MediaEvent',
        event_states: "SCHEDULED,IN_PROGRESS,DELAYED,PRE_GAME",
        asset_types: "LIVE_VIDEO,LIVE_AUDIO,EXTERNAL_LINK,LIVE_STATS",
        start_date: (Date.today - 1.days).strftime('%Y-%m-%d'),
        end_date: (Date.today + 1.days).strftime('%Y-%m-%d'),
        map_method: 'map_slim'
      })

      #S3 Models to use until amp service is available
      @schools = OasApi::S3Models::School.school_nav_ribbon
      @s3_sports = OasApi::S3Models::Sport.sports

      #Ooyala Key
      @ooyala_video_player_id = Rails.configuration.try(:ooyala_video_player_id)
      @ooyala_audio_player_id = Rails.configuration.try(:ooyala_audio_player_id)

      # Analytics
      @google_analytics_key = Rails.configuration.try(:google_analytics_key)
      @analytics_host = request.domain

      # Webmaster Tools
      @google_webmaster_tools_key = Rails.configuration.try(:google_webmaster_tools_key)
    end

    def populate_metadata
      if @not_found
        @page_title = not_found_title
        return
      end

      @page_title = title
      @last_modified = last_modified
      keyword_list = keywords

      if keyword_list.class == Array
        keyword_list.compact!
        keyword_list = keyword_list.join(', ')
      end

      set_meta_tags :title => title
      set_meta_tags :keywords => keyword_list
      set_meta_tags :description => description
      # set_meta_tags :author => author

      if social_meta?
        set_meta_tags :og => {
          :title => title,
          :site_name => site_name,
          :url => url,
          :description => twitter_description,
          :image => meta_image
        }

        set_meta_tags :twitter => {
          :card => twitter_card,
          :site => twitter_handle,
          :creator => twitter_handle,
          :title => title,
          :description => twitter_description,
          :image => meta_image,
          :url => url
        }

        if video_meta?
          set_meta_tags :video => {
            :duration => duration,
            :release_date => release_date
          }

          set_meta_tags :og => {
            :type => type,
            :updated_time => updated_time
          }

          set_meta_tags :twitter => {
            :player => [
              player_url,
              {
                :width => '435',
                :height => '251'
              }
            ]
          }
        elsif article_meta?
          set_meta_tags :og => {
            :type => type
          }

          set_meta_tags :article => {
            :section => section,
            :tag => keyword_list,
            :author => author,
            :publisher => publisher,
            :published_time => release_date,
            :modified_time => updated_time
          }
        else
          set_meta_tags :og => {
            :type => type
          }
          set_meta_tags :article => {
            :section => section,
            :tag => keyword_list,
            :author => author,
            :publisher => publisher
          }
        end
      end

      @author = author
    end

    def home?
      false
    end

    def sport?
      false
    end

    #
    # Metadata Methods
    #
    def social_meta?
      false
    end

    def video_meta?
      false
    end

    def article_meta?
      false
    end

    def conference?
      true
    end

    def school
      SeoUtils.school
    end

    def school_code_no_season(school_code_maybe_with_season)
      school_code_maybe_with_season.try(:split, '_').try(:[], 1) || school_code_maybe_with_season
    end

    def title
      "#{school.name} | Official Athletics Site"
    end

    def site_name
      "#{school.name} | Official Athletics Site"
    end

    def description
      "The Official Athletics Site for the #{school.name}.  Live coverage and the latest information for #{school.name} sports teams."
    end

    def twitter_description
      "The Official Athletics Site for the #{school.name}.  Live coverage and the latest information for #{school.name} sports teams."
    end

    def author
      "#{school.name}"
    end

    def publisher
      "#{school.name}"
    end

    def keywords
      keywords = ["Sports", "Scores", "Schedules", "Stats", "Videos", "News", "Standings",
      "College", "University", "Athletics", "Teams", "Official", "Live", school.name, school.short_name]
      school_names = []
      school_short_names = []
      school_mascots = []
      @schools.try(:each) do |curr_school|
        school_names.<< curr_school.try(:[], :longName)
        school_short_names.<< curr_school.try(:[], :shortName)
        school_mascots.<< curr_school.try(:[], :mascot)
      end
      keywords + school_names + school_short_names + school_mascots
    end

    def type
      "website"
    end

    def section
      "page"
    end

    def url
      request.original_url
    end

    def meta_image
      "http://api.silverchalice.co/sports/logos/#{school_code_no_season(school.code)}/school_logo_large_dark.png"
    end

    def twitter_card
      "summary"
    end

    def twitter_handle
      Rails.configuration.institution_twitter
    end

    def duration
      ""
    end

    def release_date
      ""
    end

    def updated_time
      ""
    end

    def last_modified
      nil
    end

    def player_url
      "https://player.ooyala.com/tframe.html?embedCode=#{@video.try(:[], :sourceId)}&pbid=#{@ooyala_video_player_id}"
    end

    def set_global_copyright
      date = Time.now
      @global_copyright = "© Copyright " + date.strftime("%Y") + " " + Rails.configuration.try(:copyright)
    end

  end
end
