module Wiki
  class PagesController < ApplicationController
    include Irwi::Extensions::Controllers::WikiPageAttachments
    include Irwi::Support::TemplateFinder

    before_action :setup_page,
      only: [:show, :history, :compare, :new, :edit, :update, :destroy, :add_attachment]
    before_action :set_community, only: [:show, :new, :update]
    before_action -> { nav_context(:wiki) }
    before_action :setup_current_user # Setup @current_user instance variable before each action

    decorates_assigned :page, :pages, :versions

    def self.page_class
      @page_class ||= Irwi.config.page_class
    end

    def self.set_page_class(arg)
      @page_class = arg
    end

    def all
      authorize sample_page
      @pages = policy_scope(Page).in_community(current_community).by_title
    end

    def show
      authorize @page
      render_not_found if @page.new_record?
    end

    def history
      authorize @page
      @versions = Irwi.config.paginator.paginate(@page.versions, page: params[:page])
      render_not_found if @page.new_record?
    end

    def compare
      authorize @page
      if @page.new_record?
        render_not_found
      else
        new_num = params[:new].to_i || @page.last_version_number # Last version number
        old_num = params[:old].to_i || 1 # First version number

        old_num, new_num = new_num, old_num if new_num < old_num # Swapping them if last < first

        versions = @page.versions.between(old_num, new_num)
        @versions = Irwi.config.paginator.paginate(versions, page: params[:page])
        @new_version = @versions.first.number == new_num ? @versions.first : versions.first
        @old_version = @versions.last.number == old_num ? @versions.last : versions.last
      end
    end

    def new
      authorize @page
    end

    def edit
      authorize @page
    end

    def update
      authorize @page
      @page.attributes = permitted_page_params
      @page.updator = current_user
      @page.creator = current_user if @page.new_record?

      if !params[:preview] && (params[:cancel] || @page.save)
        redirect_to url_for(action: :show, path: @page.path.split('/'))
      else
        render :edit
      end
    end

    def destroy
      authorize @page
      @page.destroy
      redirect_to url_for(action: :show)
    end

    private

    def permitted_page_params
      params.require(:wiki_page).permit(:title, :content, :comment)
    end

    # Retrieves wiki_page_class for this controller
    def page_class
      self.class.page_class
    end

    def render_not_found
      @path = params[:path]
      render "not_found", status: 404
    end

    # Initialize @current_user instance variable
    def setup_current_user
      @current_user = respond_to?( :current_user, true ) ? current_user : nil # Find user by current_user method or return nil
    end

    # Initialize @page instance variable
    def setup_page
      @page = page_class.find_by_path_or_new(params[:path] || '') # Find existing page by path or create new
    end

    def sample_page
      Page.new(community: current_community)
    end

    def set_community
      @page.community = current_community
    end
  end
end
