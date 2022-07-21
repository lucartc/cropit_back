class ApiController < ApplicationController

	def download
		render json: {msg: 'ok'}, status: :ok
	end

end
