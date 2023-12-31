class ApiController < ApplicationController

	def post_preflight
		head :no_content, access_control_allow_methods: "POST", access_control_allow_headers: "*"
	end

	def download
		output_images = []

		params.permit!

		sources = params["sources"].to_h
		cropped_images = params["cropped_images"]

		sources = sources.map{|key,value|
			file = Tempfile.create(binmode: true)
			file.write(Base64.decode64(value))
			{key => file}
		}

		sources.entries.each do |source|
			source_image = Vips::Image.new_from_file(source.values.first.path)

			cropped_images.each_with_index do |image,index|
				if image["source"].to_s == source.keys.first
					cropped_image_width = image["width"].to_f
					cropped_image_heigth = image["height"].to_f
					cropped_image_distance_top = image["top"].to_f
					cropped_image_distance_left = image["left"].to_f
					crop_window_width = image["crop_window_width"].to_f
					crop_window_height = image["crop_window_height"].to_f
					scale = cropped_image_width/source_image.width

					if scale > 1
						resized_image = source_image.resize(1 + ((cropped_image_width - source_image.width) / source_image.width))
					else
						resized_image = source_image.resize(1 - ((source_image.width - cropped_image_width) / source_image.width))
					end

					resized_image = resized_image.embed(
														cropped_image_distance_left,
														cropped_image_distance_top,
														crop_window_width,
														crop_window_height,
														extend: :white
													)

					output = Tempfile.create(['','.jpeg'],binmode: true)
					resized_image.write_to_file(output.path)
					output_images << output.path
				end
			end
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
