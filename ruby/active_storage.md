# ActiveStorage usage tips

Resources:

  - https://edgeguides.rubyonrails.org/active_storage_overview.html


## Rule 1: Don't use ActiveStorage.

Reasons to avoid it:

  - TODO
  - N+1 queries when you want to display images for a list of models
  - The N+1 queries are avoidable using helpers or explicit preloads, but these grow messy fast and it's easy to forget them. The need to traverse 2 associations just to display an image URL adds a lot of complexity as well as nontrivial memory bloat.
  - N+1 _webserver requests_ when you render a page displaying pictures for N users. Each image's URL points back to Rails, where the blob is queried yet again to generate a short-lived URL to the underlying object (eg. on S3). This is brilliant if your top concern is portability to a new storage backend (eg. S3 -> Google Cloud) but seems like a terrible idea when the content isn't highly sensitive and you just need to easily render lots of images.
  - Very busy logs due to the above. Maybe there's a way to silence web requests to ActiveStorage blobs, but I haven't found it yet.
  - Poor DSL for detecting whether a file is newly attached or not. (you can check the avatar.attachment.created_at timestamp, but I don't know of a cleaner way)
  - No obvious pathway for validating uploaded files _and rejecting them if they don't pass the validations_. eg. don't accept or process overly large images. There's a dubious 3rd-party gem that claims to do it. You can hand-write a model validation that will add errors if an attachment meets certain conditions, but by this point the file has already been accepted and stored, and the standard mechanisms for purging the attachment don't appear to work when called within the parent model's validation hooks.
  - More disturbingly, the [official guide](https://edgeguides.rubyonrails.org/active_storage_overview.html) doesn't contain any mention of validation whatsoever. I'd expect that a responsible guide would at least mention the notable lack of mechanisms for protecting your app from storing & processing invalid, heavy, or dangerous files. This is a major red flag to me.


## Basic usage

```rb

# Declare an attachment on a model:
has_one_attached :avatar, dependent: :destroy # there's also has_many_attached

# Attach a file from form submission param
user.avatar.attach(params[:user][:avatar])

# Attach a file from disk
file = File.open("/Users/topher/Desktop/horse.jpg")
user.avatar.attach(io: file, filename: "horse.jpg")

# Check if a file is attached
user.image.attached?

# Remove an attached file
# (NOTE: this doesn't work consistently during model lifecycle hooks!)
TODO

# Get the actual file object from an attachment (eg. to transfer it to CarrierWave)
TODO

# Preload attachment data for a set of users
# (only works when the attachment's parent is the root of this query)
User.all.with_attached_avatars

# Preload attachment data for a resource nested in query preloads:
# (so rendering image tags for the game's players' avatars won't trigger N+1 queries)
Game.all.where(...).includes(:game_system, {players: :avatar_attachment, :avatar_blob})
```
