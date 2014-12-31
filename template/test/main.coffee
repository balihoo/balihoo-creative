
QUnit.test "Basic page layout", (assert) ->

  # Get the nav header
  nav = $ 'header#top[role=banner]'
  assert.strictEqual nav.length, 1, 'There is exactly one nav header'
  assert.ok nav.is(':visible'), 'The nav header is visible'

  # Get the active navigation item
  active = $ 'header#top li.active'
  assert.strictEqual active.length, 1, 'Exactly one nav item is active'

  # Get the content page header
  header = $ '.bs-docs-header'
  assert.strictEqual header.length, 1, 'Exactly one page header'
  assert.equal $('h1', header).text().trim()
    , active.text().trim(), 'Nav item text matches page header title'
  assert.ok $('p', header).text().trim().length > 0, 'Page header text exists and is not empty'

  # Get the main content area
  main = $ 'div[role=main]'
  assert.strictEqual main.length, 1, 'Exactly one main content area'
  assert.ok $('div.bs-docs-section', main).length > 0, 'Page has at least one content section'

  # Get main topic and sidebar nav counts, they should match
  navCount = $('nav.bs-docs-sidebar ul').length - 1
  sectionCount = $('.bs-docs-section h1.page-header').length
  assert.strictEqual navCount, sectionCount, 'The side nav should have as many sections as the document'

