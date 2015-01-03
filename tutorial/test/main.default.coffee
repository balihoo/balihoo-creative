
QUnit.test "Footer link text", (assert) ->
  expected = 'Balihoo.com,npm,GitHub,Tutorial (no console)'.split /,/

  footerLinks = $ "footer .bs-docs-footer-links li a"
  assert.equal footerLinks.length, expected.length, 'There should be four links in the footer'

  for title, n in expected
    assert.equal $(footerLinks.get(n)).text().trim(), title, "Title of link ##{n} should match '#{title}'"

