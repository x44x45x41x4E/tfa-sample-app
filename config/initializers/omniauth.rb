Rails.application.config.middleware.use OmniAuth::Builder do
  provider :etalio, Figaro.env.mc_client_secret, Figaro.env.mc_client_id
end
