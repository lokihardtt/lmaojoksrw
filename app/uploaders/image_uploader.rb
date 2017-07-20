# encoding: utf-8

class ImageUploader < CarrierWave::Uploader::Base

  # Include RMagick or MiniMagick support:
  # include CarrierWave::RMagick
  include CarrierWave::MiniMagick

  # Choose what kind of storage to use for this uploader:
  # if Rails.env.eql?("production")
  #   storage :fog
  # else
    storage :file
    # asset_host Rails.env.eql?('production') ? 'http://openfreemarkettest.com' : 'http://localhost:3000'
  # end
  # storage :fog


  # Override the directory where uploaded files will be stored.
  # This is a sensible default for uploaders that are meant to be mounted:
  def store_dir
    "uploads/#{model.class.to_s.underscore}/#{mounted_as}/#{model.id}"
  
  end
  # process :optimize_image

  process :strip

  # process :watermark => "#{Rails.root}/public/image/copyright-watermark-1.gif"

  # Provide a default URL as a default if there hasn't been a file uploaded:
  # def default_url
  #   # For Rails 3.1+ asset pipeline compatibility:
  #   # ActionController::Base.helpers.asset_path("fallback/" + [version_name, "default.png"].compact.join('_'))
  #
  #   "/images/fallback/" + [version_name, "default.png"].compact.join('_')
  # end

  # Process files as they are uploaded:
  # process :scale => [200, 300]
  #
  # def scale(width, height)
  #   # do something
  # end

  # Create different versions of your uploaded files:
  version :thumb do
    process :resize_to_fit => [250, 150]
    # process :add_text
  end

  # def add_text
  #   manipulate! do |image|
  #     image.combine_options do |c|
  #       c.gravity 'South East'
  #       c.pointsize '13'
  #       c.draw "text 0,0 'openfreemarket'"
  #       c.fill 'black'
  #     end
  #     image
  #   end    
  # end

  # Add a white list of extensions which are allowed to be uploaded.
  # For images you might use something like this:
  # def extension_white_list
  #   %w(jpg jpeg gif png)
  # end

  # Override the filename of the uploaded files:
  # Avoid using model.id or version_name here, see uploader/store.rb for details.
  # def filename
  #   "something.jpg" if original_filename
  # end

  # Override the filename of the uploaded files

  private

  def strip
    manipulate! do |img|
      img.strip
      img = yield(img) if block_given?
      img
    end
  end

  def watermark(path_to_file)
    manipulate! do |img|
      img = img.composite(MiniMagick::Image.open(path_to_file), "jpg") do |c|
        c.gravity "SouthEast"
      end
    end
  end

end
