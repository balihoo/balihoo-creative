
QUnit.test "Navigation", (assert) ->
  active = $ 'header#top li.active'
  assert.equal active.text().trim(), 'Getting started', 'Active nav is Getting started page'

QUnit.test "Content", (assert) ->
  sections = $ 'div.col-md-9[role=main] .bs-docs-section h1'
  assert.equal sections.length, 3, 'There should be exactly 3 content sections'
  assert.equal $(sections[0]).text(), 'Install', 'Install section is first'
  assert.equal $(sections[1]).text(), 'Run', 'Run section is second'
  assert.equal $(sections[2]).text(), 'Develop', 'Develop section is third'

