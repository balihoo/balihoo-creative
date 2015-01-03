
QUnit.test "Change company name to ACME", (assert) ->
  assert.strictEqual $("li:contains('Balihoo')").length, 0, "Proper name Balihoo should not be present"
  assert.strictEqual $("li:contains('ACME')").length, 3, "Proper name ACME should now be present"

