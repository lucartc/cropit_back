class ApiController < ApplicationController

	def post_preflight
		head :no_content, access_control_allow_methods: "POST", access_control_allow_headers: "*"
	end

	def download
		binding.pry params
		render json: {msg: 'ok'}, status: :ok
	end

end
