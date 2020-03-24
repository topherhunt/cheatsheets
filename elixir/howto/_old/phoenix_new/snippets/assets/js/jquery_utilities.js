import $ from "jquery"

$(function(){
  $('.js-toggle-target').click(function(e){
    e.preventDefault()
    let targetSelector = $(this).data('target')
    $(targetSelector).toggle(200)
  })
})

window.testError = function() {
  return someRandomFunctionName()
}
