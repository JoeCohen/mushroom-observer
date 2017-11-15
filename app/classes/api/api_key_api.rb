class API
  # API for ApiKey
  class ApiKeyAPI < ModelAPI
    self.model = ApiKey

    self.high_detail_page_length = 100
    self.low_detail_page_length  = 1000
    self.put_page_length         = 1000
    self.delete_page_length      = 1000

    def create_params
      @for_user = parse(:user, :for_user, default: @user)
      {
        notes:    parse(:string, :app),
        user:     @for_user,
        verified: (@for_user == @user ? Time.now : nil)
      }
    end

    def validate_create_params!(params)
      raise MissingParameter.new(:app) if params[:notes].blank?
    end

    def after_create(api_key)
      return if @for_user == @user
      VerifyAPIKeyEmail.build(@for_user, @user, api_key).deliver_now
    end

    def get
      raise NoMethodForAction.new("GET", :api_keys)
    end

    def patch
      raise NoMethodForAction.new("PATCH", :api_keys)
    end

    def delete
      raise NoMethodForAction.new("DELETE", :api_keys)
    end
  end
end
