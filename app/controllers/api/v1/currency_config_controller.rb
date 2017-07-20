class Api::V1::CurrencyConfigController < ApiController
  
  api :GET, '/v1/currencies', 'Show all currency with status true'
  param :auth_token, String, desc: "Authentication Token User", required: true
  def index
    @currencies = CurrencyConfig.where(status: true)
    render "api/v1/currency_config/index"
  end

end