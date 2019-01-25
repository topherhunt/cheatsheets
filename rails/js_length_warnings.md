# How to do simple JS length warnings

### In application_helper.rb:

```ruby
def warn_of_length_limit(field_selector, max_length)
  "<div class='js-length-limit-warning' data-target-field='#{field_selector}' data-max-length='#{max_length}'>
    <div class='js-length-90pct text-warning js-hidden'>Close to the maximum length</div>
    <div class='js-length-exceeded text-danger js-hidden'>Text is too long</div>
  </div>".html_safe
end
```

### In text_length_warning.js:

```java
$(function(){
  $('.js-length-limit-warning').each(function(){
    var field_selector = $(this).data('target-field');
    var max_length = $(this).data('max-length');
    var warning_90pct = $(this).find('.js-length-90pct');
    var warning_exceeded = $(this).find('.js-length-exceeded');
    console.log('Registering length warnings for field '+field_selector+'.');

    $(field_selector).keyup(function(e){
      var current_length = $(field_selector).val().length;
      console.log('Detected keypress for field '+field_selector+'.');
      if (current_length > max_length) {
        warning_90pct.hide();
        warning_exceeded.show();
      } else if (current_length >= max_length * 0.9) {
        warning_90pct.show();
        warning_exceeded.hide();
      } else {
        warning_90pct.hide();
        warning_exceeded.hide();
      }
    });
  });
});
```

### And finally, in the form:

Just call the helper method, passing in a valid CSS id selector and the # of chars:

```
= warn_of_length_limit("#project_title", 255)
```
