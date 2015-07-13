class HomeController < ViewController
  include HomeHelper

  def index
    hash_bang_url = params.try(:[], '_escaped_fragment_')
    if hash_bang_url
      redirect_url = OasApi::S3Models::UrlRedirect.instance.hashbang_redirect_from_url(request.fullpath)
      redirect_to redirect_url, :status => 301 if redirect_url
    end

    @super_override = OasApi::Alias.all({pages: home_superhero_key}).try(:first)
    if !@super_override || !@super_override.length || !(@super_override.length > 0)
      @superhero = get_hero
    end

    @championships = OasApi::S3Models::Championships.instance.all

    super_hero_ids = @superhero.try(:map){|h|h.try(:[], :id)} || []
    @network_list = get_network_list(9, super_hero_ids)

    @content_wall = get_content_wall({limit: 10})
    @popular_links = OasApi::S3Models::PopularLink.popular_links
  end

  def home_superhero_key
    "web_home"
  end

  def home?
    true
  end

  def social_meta?
    true
  end

  def type
    "article"
  end

  def section
    "homepage"
  end
end
