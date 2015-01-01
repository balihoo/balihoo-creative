/* Insert navigation links in a sidebar based on document structure */
var comp = $('<div class="col-md-3" role="complementary">');
var nav = $('<nav class="bs-docs-sidebar hidden-print hidden-xs hidden-sm affix-top">');
var sidenav = $('<ul class="nav bs-docs-sidenav">');
$('.bs-docs-section h1').each(function(k,v){
  var heading = $(v);
  var li = $('<li class="">');
  li.append($('<a href="#' + heading.prop('id') + '">' + heading.text().trim() + '</a>'));
  var ul = $('<ul class="nav">');
  heading.siblings('h3').each(function(k,v){
    var sub = $(v);
    ul.append($('<li class=""><a href="#'+sub.prop('id')+'">' + sub.text().trim() + '</a></li>'));
  });
  li.append(ul);
  sidenav.append(li);
});
nav.append(sidenav);
nav.append('<a class="back-to-top" href="#top">Back to top</a>');
comp.append(nav);
$('div[role=main]').after(comp);

