# Creative Form Development Process

Developing creative forms comes with a fair amount of risk that something would be broken and pushed to production.  This page will serve to document proper development and deployment procedures, and should always be followed to reduce the risk of breaking something.

This will involve the use of the balihoo-creative tool, form builder, and github.

## Quick Reference

1. Get the most recent code from github
2. `git checkout -b my_new_branch_name`
3. Do work.  Test locally with the `balihoo-creative` tool.
4. `git add` any new files.  `git commit` all changes
5. `git push`.  Have code reviewed if there are any questions.
6. Use `balihoo-creative` UI to push to Stage.
7. Review in form builder then Publish.
8. Run fulfillment and test in Stage.
9. merge your feature branch into master.  If there are merge conflicts, resolve them and retest in Stage
10. Push the resulting master branch to github.
11. Run steps 6-8 for Prod.

## Starting New Work

When a new feature is defined, the first step is to retrieve the most recent code.  Do not assume that your local code is up to date; someone else might have made changes since the last time you updated.

In your console, switch to the creative repository and switch to the main branch.  For many of our own forms, this will be the forms repository and the master branch.  Then fetch and merge in any changes with git's pull command

    cd my_forms_repo_location
    git checkout master
    git pull

There should not be any problems at this point because any changes to master do not have to merge with anything locally. To assure this, you should never make changes directly to the master branch.  To add a new feature, first create a new branch to hold those changes.

    git checkout -b my_new_branch_name

It is important to only make changes in this branch that pertain to this specific feature.  If another section of this repository such as a different site also requires changes, those should be done in a separate branch.

## Making Changes.

At this point you have all the current code and a new branch where you can make changes.  Change whatever files you like using whatever tools you like.

The `balihoo-creative` tool is used to display your site in its current state in your primary browser.  Refer to the documentation for that tool for additional features.

# Committing Changes

Whenever a piece of work is done and you want to create a save point, you should commit your changes.  You must do this at the end of the story work, but you can also do this any time you reach a point that you might want to fall back to in case you break something later.

First, run `git status` to see the current change status.  Of importance is what tracked files have changed and what untracked files have been created.  Tracked refers to files that git knows about and will be saved with the site, while untracked may be files that are not part of the site but exist locally.  If there are untracked files that should be tracked, you can add them with `git add my_file_name`.  You can run `git status` again to make sure all the correct files are tracked.

To commit all changes to all tracked files, run `git commit -am "message about what changed"`  It is important to put a message here so you can refer back to what changed in case of any problems.

When work is done for this story then it is time to publish your changes.

## Publishing Changes

The code saved on your disk should be pushed to the origin reposotiry (such as github) so that others can see your work.  To do this, simply run `git push origin`.  This will push your feature branch to github separate from master.  Since this is viewable by the whole team, you could ask for a review of your changes if you have any question about the way things were done.

The resulting site should also be published to form builder using the console provided in the `balihoo-creative` tool.  **DO NOT PUSH TO PROD FIRST!**  Refer to the documentation for pushing sites to different form builder environments.  Once in form builder, you can open the form builder UI and review the site further.  This is a handy place to apply different site data and see how the design handles it.

## Going Live

Now that the changes have been tested locally and shared with others, it is time to make the site available to the world.

Every time a change is pushed to form builder it sets that form to a draft state.  Once that change is reviewed you must use the Publish button in the form builder interface to make it available to other services.

You can then run other services that will fetch this creative from form builder, such as the fulfillment process.  After fulfillment, the site can be tested at its final address to make sure everything looks as desired.

## Finalizing Work

After the changes have been reviewed in a safe environment, it it time to update the reference version for future updates.

First, merge your feature branch into master in git so that your changes will be included when future changes are made.  This can be done in the github UI with a pull request, or on the command line by switching to master then merging your changes into that.

    git checkout master
    git pull
    git merge my_new_branch_name

At this point it is possible that other changes to master have been made that conflict with your changes.  If this happens there will be a merge conflict.  There are many strategies for resolving these conflicts, so please refer to the web or other developers to help sort them out.  After conflicts are resolved you should push to stage and test again in case your merge fixes broke anything.

After the merge to master is complete and working, push resulting master branch to github.  If you merged using the github UI this is already done.

Finally, load the site in the `balihoo-creative` tool and push to Prod form builder.  Repeat the steps in Going Live to finalize Production deployment.