# encoding: utf-8
#
#  = AJAX Controller
#
#  AJAX controller can take slightly "enhanced" URLs:
#
#    http://domain.org/ajax/method
#    http://domain.org/ajax/method/id
#    http://domain.org/ajax/method/type/id
#    http://domain.org/ajax/method/type/id?other=params
#
#  Syntax of successful responses vary depending on the method.
#
#  Errors are status 500, with the response body being the error message.
#  Semantics of the possible error messages varies depending on the method.
#
#  == Actions
#
#  auto_complete::    Return list of strings matching a given string.
#  api_key::          Activate and edit ApiKey's.
#  export::           Change export status.
#  geocode::          Look up extents for geographic location by name.
#  old_translation::  Return an old TranslationString by version id.
#  pivotal::          Pivotal requests: look up, vote, or comment on story.
#  vote::             Change vote on proposed name or image.
#
################################################################################

require 'cgi'
require_dependency 'geocoder'

class AjaxController < ApplicationController
  disable_filters
  around_filter :catch_ajax_errors
  layout false

  def catch_ajax_errors
    yield
  rescue => e
    msg = e.to_s + "\n"
    if TESTING or DEVELOPMENT
      for line in e.backtrace
        break if line.match(/action_controller.*perform_action/)
        msg += line + "\n"
      end
    end
    render(:text => msg, :status => 500)
  end

  def get_session_user!
    get_session_user or raise "Must be logged in."
  end

  # Used by unit tests.
  def test
    render(:text => 'test')
  end

  # Auto-complete string as user types. Renders list of strings in plain text.
  # First line is the actual (minimal) string used to match results.  If it
  # had to truncate the list of results, the last string is "...".
  # type:: Type of string.
  # id::   String user has entered.
  def auto_complete
    type = params[:type].to_s
    string = CGI.unescape(params[:id].to_s).strip_squeeze
    if string.blank?
      render(:text => "\n\n")
    else
      auto = AutoComplete.subclass(type).new(string, params)
      results = auto.matching_strings.join("\n") + "\n"
      render(:text => results)
    end
  end

  # Activate mode: sets verified field of given ApiKey, returns nothing.
  # Edit mode: sets notes field of given ApiKey, returns new value.
  # In both cases returns error message if there is an error.
  # type::  "activate" or "edit"
  # id::    ID of ApiKey
  # value:: New value of the notes field (edit mode only)
  def api_key
    type  = params[:type].to_s
    id    = params[:id].to_s
    value = params[:value].to_s
    @user = get_session_user!
    key   = ApiKey.safe_find(id)
    if not key
      raise :runtime_no_match_id.l(:type => :api_key, :id => id)
    elsif key.user != @user
      raise :runtime_not_owner_id.l(:type => :api_key, :id => id)
    else
      case type
      when 'activate'
        key.verify!
        render(:text => '')
      when 'edit'
        if value.blank?
          raise :runtime_api_key_notes_cannot_be_blank.l
        else
          key.update_attribute(:notes, value.strip_squeeze)
        end
        render(:text => key.notes)
      else
        raise "Invalid type for api_key: #{type.inspect}"
      end
    end
  end

  # Mark an object for export. Renders updated export controls.
  # type::  Type of object.
  # id::    Object id.
  # value:: '0' or '1'
  def export
    type  = params[:type].to_s
    id    = params[:id].to_s
    value = params[:value].to_s
    if value != '0' and value != '1'
      raise "Invalid value for export: #{value.inspect}"
    elsif @user = get_session_user!
      case type
      when 'image'
        export_image(id, value)
      else
        raise "Invalid type for export: #{type.inspect}"
      end
    end
  end

  def export_image(id, value)
    @image = Image.safe_find(id)
    if not @image
      raise "Image not found: #{id.inspect}"
    elsif not @user.in_group?('reviewers')
      raise "You must be a reviewer to export images."
    else
      @image.ok_for_export = (value == '1')
      @image.save_without_our_callbacks
      render(:inline => '<%= image_exporter(@image.id, @image.ok_for_export) %>')
    end
  end

  # Get extents of a location using Geocoder. Renders ???.
  # name::   Location name.
  # format:: 'scientific' or not.
  def geocode
    name = params[:name].to_s
    if params[:format]
      name = Location.reverse_name(name) if params[:format] == "scientific"
    elsif @user = get_session_user!
      name = Location.reverse_name(name) if @user.location_format == :scientific
    end
    render(:inline => Geocoder.new(name).ajax_response)
  end

  # Return an old TranslationString by version id.
  def old_translation
    id = params[:id].to_s
    str = TranslationString::Version.find(id)
    render(:text => str.text)
  end

  # Deal with Pivotal stories.  Renders updated story, vote controls, etc.
  # type::  Type of request: 'story', 'vote', 'comment'
  # id::    ID of story.
  # value:: Value of comment or vote (as necessary).
  def pivotal
    type  = params[:type].to_s
    id    = params[:id].to_s
    value = params[:value].to_s
    case type
    when 'story'
      @story = Pivotal.get_story(id)
      render(:inline => '<%= pivotal_story(@story) %>')
    when 'vote'
      @user = get_session_user!
      @story = Pivotal.cast_vote(id, @user, value)
      render(:inline => '<%= pivotal_vote_controls(@story) %>')
    when 'comment'
      @user = get_session_user!
      story = Pivotal.get_story(id)
      @comment = Pivotal.post_comment(id, @user, value)
      @num = story.comments.length + 1
      render(:inline => '<%= pivotal_comment(@comment, @num) %>')
    else
      raise("Invalid type \"#{type}\" in Pivotal AJAX controller.")
    end
  end

  # Cast vote. Renders new set of vote controls for HTML page.
  # type::  Type of object.
  # id::    ID of object.
  # value:: Value of vote.
  def vote
    type  = params[:type].to_s
    id    = params[:id].to_s
    value = params[:value].to_s
    if @user = get_session_user!
      case type
      when 'naming'
        cast_naming_vote(id, value)
      when 'image'
        cast_image_vote(id, value)
      else
        raise "Invalid type for vote: #{type.inspect}"
      end
    end
  end

  def cast_naming_vote(id, value_str)
    @naming = Naming.safe_find(id)
    value = Vote.validate_value(value_str)
    if not value
      raise "Invalid value for vote/naming: #{value_str.inspect}"
    elsif not @naming
      raise "Invalid id for vote/naming: #{id.inspect}"
    else
      @naming.change_vote(value, @user)
      Transaction.put_naming(:id => @naming, :user => @user, :set_vote => value)
      render(:text => '')
    end
  end

  def cast_image_vote(id, value)  ##TODO: Rewrite tests
    @image = Image.safe_find(id)
    if value != '0' and not Image.validate_vote(value)
      raise "Invalid value for vote/image: #{value.inspect}"
    elsif not @image
      raise "Invalid id for vote/image: #{id.inspect}"
    else
      value = value == '0' ? nil : Image.validate_vote(value)
      anon = (@user.votes_anonymous == :yes)
      @image.change_vote(@user, value, anon)
      Transaction.put_image(:id => @image, :user => @user,
                            :set_vote => value, :set_anonymous => anon)
      render(:partial => 'image/image_vote_links')
    end
  end

  # Upload Image Template. Returns formatted HTML to be injected
  # when uploading multiple images on create observation
  def get_multi_image_template
    current_user = get_session_user!
    @licenses = License.current_names_and_ids(current_user.license) #Needed to render licenses drop down
    @image = Image.new(
                      :user => current_user,
                      :when => Time.now
                      )

    render(:partial => '/observer/form_multi_image_template')
  end


 #Uploads an image object without an observation.
 #returns image as json object
  def create_image_object
    user = get_session_user!
    @image = params[:image]

     img_when = Date.new(@image[:when][("1i")].to_i, @image[:when][("2i")].to_i,
                         @image[:when][("3i")].to_i
     )
     ##TODO: handle invalid date
     image = Image.new(
         created_at: Time.now,
         user: user,
         when: img_when,
         license_id: @image[:license].to_i,
         notes: @image[:notes],
         copyright_holder: @image[:copyright_holder]
     )

    image.image = @image[:upload]

     if !image.save
       p "unable to upload image"
       flash_object_errors(image)
     elsif !image.process_image
       p "unable to upload image"
       logger.error("Unable to upload image")
       flash_notice(:runtime_no_upload_image.t(name: (name ? "'#{name}'" : "##{image.id}")))
       flash_object_errors(image)
     else
       Transaction.post_image(
           id: image,
           date: image.when,
           notes: image.notes.to_s,
           copyright_holder: image.copyright_holder,
           license: image.license || 0
       )
       name = image.original_name
       name = "##{image.id}" if name.empty?
       flash_notice(:runtime_image_uploaded.t(name: name))
     end
    render json: image
  end
end
