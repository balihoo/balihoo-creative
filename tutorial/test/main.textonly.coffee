
QUnit.test "Look for images on page", (assert) ->

  # There better be no images on the page!
  assert.strictEqual $('img').length, 0, 'There should be no images on the page'
  
