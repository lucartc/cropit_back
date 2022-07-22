class ApiController < ApplicationController

	def post_preflight
		head :no_content, access_control_allow_methods: "POST", access_control_allow_headers: "*"
	end

	def download
		binding.pry
		file = Tempfile.create(binmode: true)
		content = params["image_content"].gsub(/data:.+;base64,/,'')
		decoded_content = Base64.decode64(content)
		cropped_images = params["cropped_images"]
		file.write(decoded_content)

		source_image = Vips::Image.new_from_file(file.path)
		
		cropped_images.each do |image|
			puts image
		end

		binding.pry

		render json: {msg: 'ok'}, status: :ok
	end

end
