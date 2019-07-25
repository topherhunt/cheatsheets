# How to record webcam video via HTML5, preview it, and capture it for upload

This guide is mostly a fleshing-out of https://developer.mozilla.org/en-US/docs/Web/API/MediaStream_Recording_API/Using_the_MediaStream_Recording_API.

Notes:

- This approach only works on Chrome & FF (as of Mar 2019).
- See RTL for the latest version of this code.


## Steps

Add the html for the preview video player and start / stop / refresh buttons:

```haml

  .js-webcam-recording-container{style: "width: 640px; height: 480px; position: relative;"}
    %video.js-recording-preview-video{controls: "", autoplay: "", style: "width: 100%; background-color: #ff0000;"}
    .js-recording-controls{style: "position: absolute; top: 10px; left: 10px;"}
      = link icon_and_text("play", "Start recording"), to: "#", class: "js-start-recording btn btn-success"
      = link icon_and_text("square", "Stop recording"), to: "#", class: "js-stop-recording js-hidden btn btn-danger"
      = link icon_and_text("refresh", "Re-record"), to: "#", class: "js-restart-recording js-hidden btn btn-warning"
      %span.js-time-remaining.js-hidden{style: "padding: 5px; color: #fff; background-color: #000; opacity: 0.5;"}

  -# for rendering & capturing the thumbnail
  %canvas.js-thumbnail-canvas.js-hidden

```



Write the JS logic which should execute on the above page:

```javascript
$(function(){

  //
  // Init the video stream
  //

  // See resources:
  // - https://developer.mozilla.org/en-US/docs/Web/API/MediaStream_Recording_API/Using_the_MediaStream_Recording_API
  // - https://developer.mozilla.org/en-US/docs/Web/API/MediaStream
  // - https://developer.mozilla.org/en-US/docs/Web/API/MediaRecorder

  console.log("Initializing webcam recording JS.");

  var videoPlayer;
  var mediaStream;
  var mediaRecorder;
  var recordingChunks;
  var recordingBlob;
  var thumbnailBlob;

  videoPlayer = $('.js-recording-preview-video')[0];
  videoPlayer.controls = false;
  recordingChunks = [];

  // Initialize (but don't start) the recording when the page loads.
  // See https://developer.mozilla.org/en-US/docs/Web/API/MediaDevices/getUserMedia
  navigator.mediaDevices.getUserMedia({audio: true, video:true})
    .then(function(stream) {
      initializeRecording(stream);
    })
    .catch(function(error) {
      console.log("getUserMedia failed:", error);
    });

  //
  // Listeners
  //

  $('.js-start-recording').click(function(e) {
    e.preventDefault();
    startRecording();
  });

  $('.js-stop-recording').click(function(e) {
    e.preventDefault();
    stopRecording();
  });

  $('.js-restart-recording').click(function(e){
    e.preventDefault();
    // We could clear and restart the recording without a page refresh, but the
    // thumbnail generation process doesn't like this for some reason (dirty canvas?)
    location.reload();
  });

  $('.js-upload-and-submit-btn').click(function(e) {
    e.preventDefault();
    submitInterview();
  });

  //
  // Handler functions
  //

  function initializeRecording(stream) {
    mediaStream = stream;

    playLiveVideoPreview();

    // TODO: Is there sense in explicitly setting the mimetype options?
    // e.g. {mimeType: 'video/webm;codecs=vp9'}
    mediaRecorder = new MediaRecorder(mediaStream);
    mediaRecorder.onwarning = function(e){ console.log("Warning: ", e); };
    mediaRecorder.onerror   = function(e){ console.log("Error: ", e); };

    mediaRecorder.ondataavailable = function(e) {
      recordingChunks.push(e.data);
      console.log("Receiving data...");
    };
  }

  function startRecording() {
    $('.js-start-recording').hide();
    $('.js-restart-recording').hide();
    $('.js-stop-recording').show();

    recordingChunks = []; // ensure any stale recording data is cleared out
    mediaRecorder.start(100); // send chunk every 100 ms

    captureThumbnail();
  }

  function stopRecording() {
    $('.js-stop-recording').hide();
    $('.js-restart-recording').show();

    mediaRecorder.stop();
    recordingBlob = new Blob(recordingChunks, {'type': 'video/webm'});
    playRecording(recordingBlob);

    // Recording is complete. Outcomes:
    // - recordingBlob and thumbnailBlob are both available for us to upload somewhere
    // - The recording is being played back to user so they can decide if they like it
  }

  //
  // Helpers
  //

  // Relies on the mediaStream having started
  function captureThumbnail() {
    var track = mediaStream.getVideoTracks()[0];
    var imageCapture = new ImageCapture(track);
    imageCapture.grabFrame()
    .then(function(imageBitmap) {
      // We have the image as imageBitmap, now we need to render it into a jpeg blob.
      // See https://developer.mozilla.org/en-US/docs/Web/API/ImageCapture#Example

      var imgWidth = imageBitmap.width;
      var imgHeight = imageBitmap.height;

      var canvas = document.querySelector('.js-thumbnail-canvas');
      canvas.width = 480; // let's ensure non-terrible image quality
      canvas.height = (canvas.width * imgHeight / imgWidth);
      canvas.getContext('2d').drawImage(imageBitmap, 0, 0, canvas.width, canvas.height);
      canvas.toBlob(function(blob) { thumbnailBlob = blob; }, 'image/jpeg', 0.8);
    })
    .catch(function(error) {
      console.error("ImageCapture.grabFrame() failed: ", error);
      console.log(error);
    });
  }

  function playLiveVideoPreview() {
    videoPlayer.srcObject = mediaStream;
    videoPlayer.controls = false;
    videoPlayer.muted = true;
  }

  function playRecording(blobToPlay) {
    videoPlayer.srcObject = undefined; // must unset this before setting src
    videoPlayer.src = window.URL.createObjectURL(blobToPlay);
    videoPlayer.controls = true;
    videoPlayer.muted = false;
  }
});
```

That's it! The above javascript will:
- init the video stream and display a preview of what the webcam sees
- detect "start recording" click, start recording, and capture a thumbnail too
- detect "stop recording" click, stop recording, and play the video back for the user
- provide recordingBlob and thumbnailBlob for us to subsequently upload or something
