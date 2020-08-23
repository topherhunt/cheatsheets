# CarrierWave usage tips

Tips on basic CarrierWave usage in an ActiveRecord context.

Further resources:

  - https://github.com/carrierwaveuploader/carrierwave
  - https://github.com/carrierwaveuploader/carrierwave/wiki/How-to%3A-Validate-image-file-size
  - https://medium.com/@mauddev/rails-5-and-carrierwave-53960ec20c4b

A basic Uploader class:

```rb
# This Uploader defines the settings, processing rules, variants, & validations
# for a generic image attachment.
# - For detailed config, see https://github.com/carrierwaveuploader/carrierwave
# - You can also run `rails g uploader Avatar` to get a template w guiding comments.
class ImageUploader < CarrierWave::Uploader::Base
  include CarrierWave::MiniMagick # add support for image transformations

  # Override the directory where uploaded files will be stored.
  # This is a sensible default for uploaders that are meant to be mounted:
  def store_dir
    "uploads/#{Rails.env}/#{model.class.to_s.underscore}_#{mounted_as}/#{model.id}"
  end

  # Resize the original file to fit within 800x800px (without cropping).
  # We don't use this full size much except for the game show page.
  # See https://github.com/carrierwaveuploader/carrierwave#processing-methods-mini_magick
  process resize_to_limit: [800, 800]

  # Version: medium-size, cropped to square (used on user profile page)
  version :medium do
    process resize_to_fill: [400, 400]
  end

  # Version: thumbnail, cropped to square
  version :thumb do
    process resize_to_fill: [100, 100]
  end

  # Validations live here on the uploader rather than on the parent model.
  # This ensures the file won't be processed unless validations pass.
  # File validations are only run when a file is newly attached to a model.
  # (ie. not on subsequent, unrelated changes to the model)

  # See also https://github.com/carrierwaveuploader/carrierwave#cve-2016-3714-imagetragick
  def content_type_whitelist
    /image\/.+/
  end

  # See https://github.com/carrierwaveuploader/carrierwave/wiki/How-to:-Validate-image-file-size
  def size_range
    1.byte..3.megabytes
  end

  # Add a white list of extensions which are allowed to be uploaded.
  # For images you might use something like this:
  # def extension_whitelist
  #   %w(jpg jpeg gif png)
  # end

  # Override the filename of the uploaded files:
  # Avoid using model.id or version_name here, see uploader/store.rb for details.
  # def filename
  #   "something.jpg" if original_filename
  # end
end


```

Example usage:

```rb

# Mount an attachment on an ActiveRecord model:
# - ImageUploader defines the processing, variants, & file validations.
# - The model must have a `picture` text column present, which stores the filename.
mount_uploader :picture, ImageUploader
def picture_attached?() picture.file.present? end # convenience helper

# Attach a file to a model:
user.picture = params[:user][:picture] # from a file upload in a form submission
user.picture = File.open("/Users/topher/Desktop/horse.jpg") # or from a plain File
# The file is "cached" and variants are processed as soon as you assign it. (if valid)
user.save! # On save, the file & variants are moved to their permanent home.

# Attach a file from a remote URL:
user.remote_picture_url = "https://..."
user.save # expect validation errors if the file couldn't be loaded (eg. request failure)

# Remove attachment:
user.update!(picture: nil) # a callback will delete the file from storage

# Check if a picture is attached
user.picture.file.present? # or user.picture_attached?

# URL for an attachment (original file)
user.picture.url # will be nil if no file is attached

# URL for a variant of an attachment
user.picture.thumb.url

# Filename of an attachment
user.picture.file.filename # there's also user.picture_identifier

# Recreate any missing versions for all records in this class:
# (You'll need to re-run this for each model class and each attachment name.)
User.where("picture IS NOT NULL").each { |u| u.picture.recreate_versions! }

# Clear out "abandoned" cached uploads (accumulated due to model validation errers etc.)
CarrierWave.clean_cached_files!(600) # >= 10 minutes old

```
