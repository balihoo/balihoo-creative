
QUnit.test "Navigation", (assert) ->
  active = $ 'header#top li.active'
  assert.equal active.text().trim(), 'Getting started', 'Active nav is Getting started page'

QUnit.test "Content", (assert) ->
  sections = $ 'div.col-md-9[role=main] .bs-docs-section h1'
  assert.equal sections.length, 4, 'There should be exactly 4 content sections'
  assert.equal $(sections[0]).text(), 'Install', 'Install section is first'
  assert.equal $(sections[1]).text(), 'Setup', 'Setup section is second'
  assert.equal $(sections[2]).text(), 'Run', 'Run section is third'
  assert.equal $(sections[3]).text(), 'Develop', 'Develop section is fourth'

