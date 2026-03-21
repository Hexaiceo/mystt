# Handle Feature/Bug Command

Handles the changes proposed in JIRA issue.

## Instructions

Follow this systematic approach to handle a new feature: **$ARGUMENT**
**$ARGUMENT** Can be provided only as a issue name in JIRA like SUPP-1234, SUPP-14566 etc.

1. **Gather Info**
    - Gather info about feature from "$ARGUMENT AI Context" confluence subpage.
    - If JIRA issue $ARGUMENT dont have "AI-Ready" label - stop processing IMMEDIATELY and tell user, that this issue is not yet approved.
    - Change the status of $ARGUMENT JIRA issue to "IN PROGRESS".

2. **Prepare environment**
    - Use plan created as subpage under https://eurocontrol-nm.atlassian.net/wiki/spaces/SUPP/pages/1521713456/AI+Jira+Tasks+PoC confluence page using $ARGUMENT as page name. 
    - Use all info provided there as input for agent @workflow-orchestrator. Use "$ARGUMENT AI Context" confluence subpage as current context.
    - Do not include on page and do not perform: "Performance Optimization Strategy", "Accessibility & UX Considerations", "Implementation Phases", "Risk Management", "Success Metrics", "Recommendations".
    
3. **Code changes**
    - For each repository in "Affected repositories" section checkout a new branch named $ARGUMENT - so it will be possible to follow feature branch strategy.
    - When finishing code changes verify if application is building and starting correctly. If not - analyze the startup logs and fix the issues until app is able to run.
    - Update "$ARGUMENT AI Context" confluence subpage with current context, so in case of a need of additional changes - you can continue the work.

4. **Verification**
    - After all code changes and fix of the application, change $ARGUMENT JIRA issue status to "VERIFICATION".
