# Finalize working on Feature/Bug Command

Finalization of handling the JIRA issue.

## Instructions

Follow this systematic approach to handle a new feature: **$ARGUMENT**
**$ARGUMENT** Can be provided only as a issue name in JIRA like SUPP-1234, SUPP-14566 etc.

1. **Gather Info**
    - Gather info about feature from JIRA issue provided as $ARGUMENT and confluence subpage "$ARGUMENT AI Context".
    - Check if $ARGUMENT JIRA issue has "AI-Ready" label. If it has, then proceed, otherwise stop immediatley and inform user that JIRA ticket is not ready for finalization.
    - Push the changes in repositories listed in paragraph in "$ARGUMENT Requirements" confluence page, with a commit messages describing the changes.

2. **Summary**
    - Summarize a commit changes and put a comment in $ARGUMENT JIRA issue.
    - Create new confluence page (or update existing one) under $ARGUMENT page, called "$ARGUMENT Documentation update" which will be used to update current documentation of the system (high-level design and low-level design).

3. **Updates**
    - Remove the label "AI-Ready" and add "AI-Implemented" in $ARGUMENT JIRA issue.
    - Change the status of $ARGUMENT JIRA issue to "DONE".
    - Remove "$ARGUMENT AI Context" confluence subpage, as the current feature is implemented, the context will not be needed.
