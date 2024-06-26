# frozen_string_literal: true

#
#  = Comments Controller
#
#  == Actions
#   L = login required
#   R = root required
#   V = has view
#   P = prefetching allowed
#
#  ==== Searches and Indexes
#  index:: (params call private methods below)
#
#  - list_comments::
#  - show_comments_by_user::
#  - show_comments_for_target::
#  - show_comments_for_user::
#  - comment_search::
#  - index_comment::
#  - show_selected_comments::
#
#  ==== Show, CRUD actions
#  show:: (use params for next and prev)
#  new::
#  create::
#  edit::
#  update::
#  destroy::
#
################################################################################
class CommentsController < ApplicationController
  before_action :login_required
  before_action :pass_query_params, except: [:index]
  before_action :disable_link_prefetching, except: [:new, :edit, :show]

  # Bullet doesn't seem to be able to figure out that we cannot eager load
  # through polymorphic relations, so I'm just disabling it for these actions.
  around_action :skip_bullet, if: -> { defined?(Bullet) }, only: [:index]

  ##############################################################################
  #
  #  :section: Searches and Indexes
  #
  ##############################################################################

  @index_subaction_param_keys = [
    :target,
    :pattern,
    :by_user,
    :for_user,
    :by
  ].freeze

  @index_subaction_dispatch_table = {
    target: :show_comments_for_target,
    pattern: :comment_search,
    by_user: :show_comments_by_user,
    for_user: :show_comments_for_user,
    by: :index_comment
  }.freeze

  # Disable cop because method definition prevents a
  # Rails/LexicallyScopedActionFilter offense
  # https://docs.rubocop.org/rubocop-rails/cops_rails.html#railslexicallyscopedactionfilter
  def index # rubocop:disable Lint/UselessMethodDefinition
    super
  end

  private

  def default_index_subaction
    list_comments
  end

  # Show selected list of comments, based on current Query.  (Linked from
  # show_comment, next to "prev" and "next"... or will be.)
  def index_comment
    query = find_or_create_query(:Comment, by: params[:by])
    show_selected_comments(query, id: params[:id].to_s, always_index: true)
  end

  # Show list of latest comments. (Linked from left panel.)
  def list_comments
    query = create_query(:Comment, :all, by: :created_at)
    show_selected_comments(query)
  end

  # Shows comments by a given user, most recent first. (Linked from show_user.)
  def show_comments_by_user
    user = find_or_goto_index(User, params[:by_user].to_s) || @user
    return unless user

    query = create_query(:Comment, :by_user, user: user)
    show_selected_comments(query)
  end

  # Shows comments for a given user, most recent first. (Linked from show_user.)
  def show_comments_for_user
    user = find_or_goto_index(User, params[:for_user].to_s) || @user
    return unless user

    query = create_query(:Comment, :for_user, user: user)
    show_selected_comments(query)
  end

  # Shows comments for a given object, most recent first. (Linked from the
  # "and more..." thingy at the bottom of truncated embedded comment lists.)
  def show_comments_for_target
    model = Comment.safe_model_from_name(params[:type])
    if !model
      flash_error(:runtime_invalid.t(type: '"type"',
                                     value: params[:type].to_s))
      redirect_back_or_default(action: :index)
    elsif (target = find_or_goto_index(model, params[:target].to_s))
      query = create_query(:Comment, :for_target, target: target.id,
                                                  type: target.class.name)
      show_selected_comments(query)
    end
  end

  # Display list of Comment's whose text matches a string pattern.
  def comment_search
    pattern = params[:pattern].to_s
    if pattern.match?(/^\d+$/) &&
       (comment = Comment.safe_find(pattern))
      redirect_to(action: :show, id: comment.id)
    else
      query = create_query(:Comment, :pattern_search, pattern: pattern)
      show_selected_comments(query)
    end
  end

  # Show selected list of comments.
  def show_selected_comments(query, args = {})
    # (Eager-loading of names might fail when comments start to apply to
    # objects other than observations.)
    args = {
      action: :index,
      num_per_page: 25,
      include: [:target, :user]
    }.merge(args)

    # Add some alternate sorting criteria.
    args[:sorting_links] = [
      # ["summary",  :sort_by_summary.t],
      ["user", :sort_by_user.t],
      ["created_at", :sort_by_posted.t],
      ["updated_at", :sort_by_updated_at.t]
    ]

    # Paginate by letter if sorting by user.
    if (query.params[:by] == "user") ||
       (query.params[:by] == "reverse_user")
      args[:letters] = "users.login"
      # Paginate by letter if sorting by summary.
      # elsif (query.params[:by] == "summary") or
      #    (query.params[:by] == "reverse_summary")
      #   args[:letters] = 'comments.summary'
    end

    @full_detail = (query.flavor == :for_target)

    show_index_of_objects(query, args)
  end

  public

  ##############################################################################
  #
  #  :section: Show
  #
  ##############################################################################

  # Display comment by itself.
  # Linked from: show_<object>, index
  # Inputs: params[:id] (comment)
  # Outputs: @comment, @object
  def show
    store_location
    return unless (@comment = find_comment!)

    case params[:flow]
    when "next"
      redirect_to_next_object(:next, Comment, params[:id]) and return
    when "prev"
      redirect_to_next_object(:prev, Comment, params[:id]) and return
    end

    @target = @comment.target
    allowed_to_see!(@target)
  end

  private

  def find_comment!
    find_or_goto_index(Comment, params[:id].to_s)
  end

  # Make sure users can't see/add comments on objects they aren't allowed to
  # view!  Redirect and return +false+ if they can't, else return +true+.
  def allowed_to_see!(object)
    return true unless object.respond_to?(:is_reader?) &&
                       !object.is_reader?(@user) &&
                       !in_admin_mode?

    flash_error(:runtime_show_description_denied.t)
    parent = object.parent
    redirect_to(controller: parent.show_controller,
                action: parent.show_action, id: parent.id)
    false
  end

  public

  ##############################################################################
  #
  #  :section: CRUD actions
  #
  ##############################################################################

  # Form to create comment for an object.
  # Linked from: show_<object>
  # Inputs:
  #   params[:id] (object id)
  #   params[:type] (object type)
  #   params[:comment][:summary]
  #   params[:comment][:comment]
  # Success:
  #   Redirects to show_<object>.
  # Failure:
  #   Renders add_comment again.
  #   Outputs: @comment, @object
  def new
    return unless (@target = load_target(params[:type], params[:target])) &&
                  allowed_to_see!(@target)

    @comment = Comment.new(target: @target)

    respond_to do |format|
      format.html
      format.js do
        render(layout: false)
      end
    end
  end

  def create
    return unless (@target = load_target(params[:type], params[:target])) &&
                  allowed_to_see!(@target)

    @comment = Comment.new(target: @target)
    @comment.attributes = permitted_comment_params if params[:comment]

    save_comment_or_flash_errors_and_redirect!
  end

  private

  def permitted_comment_params
    params[:comment].permit([:summary, :comment])
  end

  def save_comment_or_flash_errors_and_redirect!
    unless @comment.save
      flash_object_errors(@comment)
      respond_to do |format|
        format.html { render(:new) and return }
        format.js do
          render("form_reload", locals: { action: :create }) and return
        end
      end
    end

    @comment.log_create
    flash_notice(:runtime_form_comments_create_success.t(id: @comment.id))

    respond_to do |format|
      format.html do
        redirect_with_query(controller: @target.show_controller,
                            action: @target.show_action, id: @target.id)
      end
      format.js
    end
  end

  public

  # Form to edit a comment for an object..
  # Linked from: show_comment, show_object.
  # Inputs:
  #   params[:id]
  #   params[:comment][:summary]
  #   params[:comment][:comment]
  # Success:
  #   Redirects to show_object.
  # Failure:
  #   Renders edit_comment again.
  #   Outputs: @comment, @object
  def edit
    return unless (@comment = find_comment!)

    @target = comment_target
    return unless allowed_to_see!(@target)
    return unless check_permission_or_redirect!(@comment, @target)

    respond_to do |format|
      format.js
      format.html
    end
  end

  def update
    return unless (@comment = find_comment!)

    @target = comment_target
    return unless allowed_to_see!(@target) &&
                  check_permission_or_redirect!(@comment, @target)

    @comment.attributes = permitted_comment_params if params[:comment]

    unless comment_updated?
      respond_to do |format|
        format.js do
          render(partial: "form_reload", locals: { action: :update })
        end
        format.html { render(:edit) and return }
      end
    end

    respond_to do |format|
      format.js
      format.html do
        redirect_with_query(controller: @target.show_controller,
                            action: @target.show_action, id: @target.id)
      end
    end
  end

  # Callback to destroy a comment.
  # Linked from: show_comment, show_object.
  # Redirects to show_object.
  # Inputs: params[:id]
  # Outputs: none
  def destroy
    return unless (@comment = find_comment!)

    @target = @comment.target
    if !check_permission!(@comment)
      # all html requests redirect to object show page
    elsif !@comment.destroy
      flash_error(:runtime_form_comments_destroy_failed.t(id: params[:id]))
    else
      @comment.log_destroy
      flash_notice(:runtime_form_comments_destroy_success.t(id: params[:id]))
    end
    respond_to do |format|
      format.js
      format.html do
        redirect_with_query(controller: @target.show_controller,
                            action: @target.show_action, id: @target.id)
      end
    end
  end

  private

  def comment_target
    load_target(@comment.target_type, @comment.target_id)
  end

  def load_target(type, id)
    case type
    when "Observation"
      load_for_show_observation_or_goto_index(id)
    else
      target = Comment.find_object(type, id.to_s)
      redirect_back_or_default("/") unless target
      target
    end
  end

  def check_permission_or_redirect!(comment, target)
    return true if check_permission!(comment)

    redirect_with_query(controller: target.show_controller,
                        action: target.show_action, id: target.id)
    false
  end

  def comment_updated?
    if !@comment.changed?
      flash_notice(:runtime_no_changes.t)
      true
    elsif !@comment.save
      flash_object_errors(@comment)
      false
    else
      @comment.log_update
      flash_notice(:runtime_form_comments_edit_success.t(id: @comment.id))
      true
    end
  end
end
