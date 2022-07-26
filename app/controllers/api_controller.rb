class ApiController < ApplicationController

	def post_preflight
		head :no_content, access_control_allow_methods: "POST", access_control_allow_headers: "*"
	end

	def download
		output_images = []

		sources = params["sources"]
		cropped_images = params["cropped_images"]

		sources = sources.map{|key,value|
			file = new Tempfile.create(binmode: true)
			file.write(Base64.decode64(value))
			{key => file}
		}

		sources.each do |source|{
			source_image = Vips::Image.new_from_file(source.value.path)

			cropped_images.each_with_index do |image,index|
				if image["source"].to_s == source.key.to_s
					cropped_image_width = image["image_width"].to_f
					cropped_image_heigth = image["image_height"].to_f
					cropped_image_distance_top = image["top"].to_f
					cropped_image_distance_left = image["left"].to_f
					crop_window_width = image["crop_windo_width"].to_f
					crop_window_heigth = image["crop_window_height"].to_f
					scale = cropped_image_width.to_f/source_image.width.to_f

					if scale > 1
						source_image = source_image.resize(1 + ((cropped_image_width - source_image.width) / source_image.width))
					else
						source_image = source_image.resize(1 - ((source_image.width - cropped_image_width) / source_image.width))
					end

					source_image = source_image.embed(
														cropped_image_distance_left,
														cropped_image_distance_top,
														crop_window_width,
														crop_window_heigth,
														extend: :white
													)

					output = Tempfile.create(['','.jpeg'],binmode: true)
					source_image.write_to_file(output.path)
					output_images << output.path
				end
			end
		}

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
