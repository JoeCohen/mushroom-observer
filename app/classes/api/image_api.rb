class API
  # API for Image
  class ImageAPI < ModelAPI
    self.model = Image

    self.high_detail_page_length = 100
    self.low_detail_page_length  = 1000
    self.put_page_length         = 1000
    self.delete_page_length      = 1000

    self.high_detail_includes = [
      :user
    ]

    # rubocop:disable Metrics/AbcSize
    def query_params
      {
        where:           sql_id_condition,
        created_at:      parse_range(:time, :created_at),
        updated_at:      parse_range(:time, :updated_at),
        date:            parse_range(:date, :date, help: :when_taken),
        users:           parse_array(:user, :user, help: :uploader),
        names:           parse_array(:name, :name, as: :id),
        synonym_names:   parse_array(:name, :synonyms_of, as: :id),
        children_names:  parse_array(:name, :children_of, as: :id),
        locations:       parse_array(:location, :location, as: :id),
        projects:        parse_array(:project, :project, as: :id),
        species_lists:   parse_array(:species_list, :species_list, as: :id),
        has_observation: parse(:boolean, :has_observation,
                               limit: true, help: 1),
        size:            parse(:enum, :size,
                               limit: Image.all_sizes - [:full_size],
                               help: :min_size),
        content_types:   parse_array(:enum, :content_type,
                                     limit: Image.all_extensions),
        has_notes:       parse(:boolean, :has_notes),
        notes_has:       parse(:string, :notes_has, help: 1),
        copyright_holder_has: parse(:string, :copyright_holder_has, help: 1),
        license:         parse(:license, :license),
        has_votes:       parse(:boolean, :has_votes),
        quality:         parse_range(:quality, :quality),
        confidence:      parse_range(:confidence, :confidence),
        ok_for_export:   parse(:boolean, :ok_for_export)
      }
    end
    # rubocop:enable Metrics/AbcSize

    def create_params
      parse_create_params!
      {
        when:             parse(:date, :date, default: @default_date,
                                              help: :when_taken),
        notes:            parse(:string, :notes, default: ""),
        copyright_holder: parse(:string, :copyright_holder,
                                limit: 100, default: user.legal_name),
        license:          parse(:license, :license, default: user.license),
        original_name:    parse(:string, :original_name,
                                limit: 120, default: nil, help: :original_name),
        projects:         parse_array(:project, :projects,
                                      must_be_member: true) || [],
        observations:     @observations,
        user:             @user
      }.merge(upload_params)
    end

    def update_params
      {
        when:             parse(:date, :set_date, help: :when_taken),
        notes:            parse(:string, :set_notes),
        copyright_holder: parse(:string, :set_copyright_holder, limit: 100),
        license:          parse(:license, :set_license),
        original_name:    parse(:string, :set_original_name,
                                limit: 120, default: nil, help: :original_name)
      }
    end

    def validate_create_params!(_params)
      raise MissingUpload.new unless @upload
    end

    def build_object
      super
    ensure
      @upload.clean_up if @upload
    end

    def after_create(img)
      img.process_image || raise(ImageUploadFailed.new(img))
      @observations.each do |obs|
        obs.update(thumb_image_id: img.id) unless obs.thumb_image_id
        obs.log_create_image(img)
      end
      return unless @vote
      img.change_vote(@user, @vote, (@user.votes_anonymous == :yes))
    end

    ############################################################################

    private

    def parse_create_params!
      @observations = parse_array(:observation, :observations,
                                  must_have_edit_permission: true) || []
      @default_date = @observations.any? ? @observations.first.when : Date.today
      @vote = parse(:enum, :vote, limit: Image.all_votes)
      @upload = prepare_upload
    end

    def upload_params
      return {} unless @upload
      {
        image:            @upload.content,
        upload_length:    @upload.content_length,
        upload_type:      @upload.content_type,
        upload_md5sum:    @upload.content_md5
      }
    end
  end
end
