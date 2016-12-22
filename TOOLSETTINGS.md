# Tool Settings.

The Balihoo Creative tool is always under development.  Any changes will be documented in the [change log](CHANGELOG.md).  Most of the time those features should just affect the tool itself and the features it provides, but sometimes those changes may affect how creatives are loaded or edited.

## Backward Compatibility

Generally, you should be able to upgrade the balihoo-creative tool to one that does things a little differently without changing the creatives at all.  Any new features should check whether or not that feature is being used in the current creative, and if not fall back to the way it was done when that creative was made.

Therefore, settings will be added to the `.balihoo-creative.json` file in each project that tells which features this creative uses.  Some creatives can use new features while others use old, all with the same version of the tool.

If a certain creative contains a tool setting that this version of the tool doesn't know about, it will error and let you know to upgrade to a newer version of the tool for this creative.  Again, this should not break your ability to edit older creatives.

## Settings format

The `.balihoo-creative.json` file may optionally contain a section for `toolSettings`.  The file will look something like this:

```json
{
  "name": "example",
  "description": "Example of config file with toolSettings",
  "channel": "Local Websites",
  "template": "main",
  "...": "other stuff here",
  "port": 8088,
  "toolSettings": {
    "modelCodeVersion": 1
  }
}
```

## Settings Versions and Upgrade Paths

### modelCodeVersion

Changes to the model code that is saved with the form.  This model code includes fields that are referenced by mustache templates.

####  modelCodeVersion: 1
This changes the `assets` collection to have files referenced as `filename_ext` instead of just `filename` without any extension.  This provides two advantages.  

First, it prevents asset key collisions when two assets start with the same basename, such as foo.jpg and foo.png, but also vendor.js and vendor/thing.js.

Second, it allows us to view the model code and download the assets complete with file extension.  This is necessary in the case when source code for a form has been lost and can be recovered by downloading the form and its assets.
 
To convert creatives from previous versions of this setting, add file extensions to any assets mustache references after an underscore.  For example, `{{assets.styles.main}}` would become `{{assets.styles.main_css}}`.

Please note this change only affects files under `assets`.  It does not affect other mustache tags.  Tags that reference other mustache files still do not include file extension, as only .mustache is supported.
