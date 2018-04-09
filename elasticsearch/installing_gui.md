# Installing a bare-bones ElasticSearch query GUI

Notes:
- Assumes you've already built out basic ES integration as described in `installing.md`
- HTML uses Bootstrap CSS
- Allows queries, but not arbitrary requests. Use `curl` for those.

## Add the new routes

```
# config/routes.rb
namespace :admin do
  get "elasticsearch_gui" => "elasticsearch_gui#page", as: "elasticsearch_gui"
  post "elasticsearch_gui/query" => "elasticsearch_gui#query"
end
```

## Add the controller

```
# app/controllers/admin/elasticsearch_gui_controller.rb
class Admin::ElasticsearchGuiController < ApplicationController
  http_basic_authenticate_with name: "topher", password: "esgui"

  def page
    @all_indexes = all_indexes
  end

  def query
    begin
      response = client.search({
        index: params[:indexes],
        body: params[:query]
      })
      results = response.as_json['hits']['hits']
      render json: {
        success: true,
        num_results: results.count,
        results: results.to_json
      }
    rescue => e
      render json: {error: e.to_s}
    end
  end

  private

  def all_indexes
    response = client.perform_request('GET', '_aliases')
    response.as_json['body'].keys.sort
  rescue => e
    []
  end

  def client
    Elasticsearch::Model.client
  end
end
```

## Add the view

```
# app/views/admin/elasticsearch_gui/page.haml
.row
  .col-sm-6
    %h1 ElasticSearch GUI
    - if @all_indexes.empty?
      .alert.alert-danger Warning: No indexes found. Is ElasticSearch running?
    %label Indexes (default is "all")
    %select#js-query-indexes.js-chosen{multiple: true, data: {placeholder: "Indexes"}}
      - @all_indexes.each do |index_name|
        %option{value: index_name}= index_name
    %label Query
    %textarea#js-query-input.form-control{style: "width: 100%; height: 400px; font-family: monospace; font-size: 11px;"}
    .text-right
      %a#js-submit-query.btn.btn-success{href: "#"} Run
  .col-sm-6{style: "max-height: 500px; overflow: auto;"}
    #js-query-stats
      %p
        = "# results:"
        %span#js-query-num-results
    %pre#js-query-output{style: "font-size: 11px;"}
    #js-response-error.well.well-sm.text-danger{style: "font-family: monospace; font-size: 11px;"}
```

## Add Jquery listeners and ajax for the page

```
# app/assets/javascript/elasticsearch_gui.js
$(function(){

  $('.js-chosen').chosen({
    allow_single_deselect: true,
    search_contains: true,
    width: '100%'
  });

  var prettyPrintJson = function(string){
    try {
      return JSON.stringify(JSON.parse(string), null, '  ')
    } catch(e) {
      alert("Error parsing JSON.");
      raise(e);
    }
  };

  $('#js-submit-query').click(function(e){
    e.preventDefault();
    var query = $('#js-query-input').val().replace(/\n\s*/g, '');
    var indexes = ($('#js-query-indexes').val() || []).join(",");

    $('#js-query-stats').hide();
    $('#js-query-output').hide();
    $('#js-response-error').hide();

    $('#js-query-input').val(prettyPrintJson(query));

    $.ajax({
      type: 'POST',
      url: '/admin/elasticsearch_gui/query',
      data: {query: query, indexes: indexes},
      success: function(response){
        console.log(response);
        if (response.success) {
          $('#js-query-stats').show();
          $('#js-query-num-results').text(response.num_results);
          $('#js-query-output').show().text(prettyPrintJson(response.results));
        } else {
            $('#js-response-error').show().text(response.error);
        }
      },
      error: function(){
        $('#js-response-error').show().text('Error: no response or malformed response from server.');
      }
    });
  });

  $('#js-query-stats').hide();
  $('#js-query-output').hide();
  $('#js-response-error').hide();

});
```
