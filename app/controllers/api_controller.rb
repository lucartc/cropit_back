class ApiController < ApplicationController

	def post_preflight
		head :no_content, access_control_allow_methods: "POST", access_control_allow_headers: "*"
	end

	def download
		file = Tempfile.create(binmode: true)
		output_images = []
		content = params["image_content"].gsub(/data:.+;base64,/,'')
		decoded_content = Base64.decode64(content)
		cropped_images = params["cropped_images"]
		file.write(decoded_content)

		source_image = Vips::Image.new_from_file(file.path)
		
		cropped_images.each_with_index do |image,index|
			cropped_image_width = image["image_width"]
			cropped_image_heigth = image["image_height"]
			cropped_image_distance_top = image["top"]
			cropped_image_distance_left = image["left"]
			scale = cropped_image_width.to_f/source_image.width.to_f

			if scale > 1
				source_image = source_image.resize(1 + ((cropped_image_width.to_f - source_image.width.to_f) / source_image.width.to_f))
			else
				source_image = source_image.resize(1 - ((source_image.width.to_f - cropped_image_width.to_f) / source_image_width.to_f))
			end

			source_image = source_image.embed(
								cropped_image_distance_left,
								cropped_image_distance_top,
								cropped_image_width,
								cropped_image_heigth,
								extend: :white
							)
			output = Tempfile.create(['','.jpeg'],binmode: true)
			source_image.write_to_file(output.path)
			output_images << output.path
		end

		zipfile = Tempfile.create(binmode: true)

		Zip::File.open(zipfile.path,create: true) do |zip|
			output_images.each_with_index do |saved_image,index|
				zip.add("image_#{index}.jpeg",saved_image)
			end
		end

		zip = File.open(zipfile.path,'r')

		File.delete(*output_images)
		
		send_data zip.read, :filename => 'images.zip', :type => 'application/zip'
	end
end
