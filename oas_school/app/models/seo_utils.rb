module OasSchool
  class SeoUtils
    def self.hostname
      @hostname ||= Rails.configuration.try(:my_hostname)
    end

    def self.school
      @school ||= OasApi::School.find(Amp.configuration.try(:school_code))
    end

    def self.keywords_for_video(video, sport_metadata=nil)
      school = self.school
      if sport_metadata
        [school.name, school.nickname, sport_metadata, "News", "Information", "Preview",
          "Recap", "Sports", "Latest", "Game", "Daily", "Update", "Audio", "Video", "Coverage",
          "Clips", "Highlights", "Show", "Program" ] + video.try(:[], :tags).to_a
      else
        [school.name, school.nickname, "News", "Information", "Preview",
          "Recap", "Sports", "Latest", "Game", "Daily", "Update", "Audio", "Video", "Coverage",
          "Clips", "Highlights", "Show", "Program" ] + video.try(:[], :tags).to_a
      end
    end

    def self.keywords_for_volar(video, sport_metadata=nil)
      school = self.school
      if sport_metadata
        [school.name, school.nickname, sport_metadata, "News", "Information", "Preview",
          "Recap", "Sports", "Latest", "Game", "Daily", "Update", "Audio", "Video", "Coverage",
          "Clips", "Highlights", "Show", "Program" ] + video.try(:[], :section_title).to_a
        else
          [school.name, school.nickname, "News", "Information", "Preview",
            "Recap", "Sports", "Latest", "Game", "Daily", "Update", "Audio", "Video", "Coverage",
            "Clips", "Highlights", "Show", "Program" ] + video.try(:[], :section_title).to_a
          end
        end

    def self.keywords_for_article(article)
      school = self.school
      tags = article.try(:[], :tags)
      keys = [school.name, school.nickname, "News", "Information", "Preview", "Recap", "Sports",
         "Latest", "Game", "Daily", "Update", "Articles", "Coverage"]
      keys + tags if tags

      keys.compact!
      keys.to_sentence
    end
  end
end
