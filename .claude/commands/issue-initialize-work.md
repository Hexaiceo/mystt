# Initialize working on Feature/Bug Command

Create confluence structure to initialize the work on JIRA issue.

## Instructions

Follow this systematic approach to create a new feature: **$ARGUMENT**
**$ARGUMENT** Can be provided only as a issue name in JIRA like SUPP-1234, SUPP-14566 etc.

1. **Gather Info**
    - Gather info about feature from JIRA issue provided as $ARGUMENT. Get also all comments from JIRA issue. 
    - If issue has "AI-Ready" label - stop processing IMMEDIATELY and tell user, that this issue is already closed for planning.
    - Pass this info to @workflow-orchestrator to create a structured plan, which will be stored in confluence subpage and used later for other agents as an input.

2. **Feature Planning**
    - Put the created plan under https://eurocontrol-nm.atlassian.net/wiki/spaces/SUPP/pages/1521713456/AI+Jira+Tasks+PoC confluence page. Use $ARGUMENT as a new page name. If page already exist - update it.
    - Create a "$ARGUMENT Requirements" subpage with list of required changes, create a paragraph with a list of repositories which needs code changes named "Affected repositories". If page already exist - update it.
    - Create an "$ARGUMENT Architecture" subpage with list of architectural changes provided by @software-architect. If page already exist - update it.
    - Do not include on pages and do not perform: "Performance Optimization", "Performance Optimization Strategy", "Accessibility & UX Considerations", "Implementation Phases", "Risk Management", "Success Metrics", "Recommendations".

3. **Summarization**
    - Put a comment in JIRA with link to created page and short summarization of changes. Add "If current plan and overview is fine, please add 'AI-Ready' label to this issue'" at the end of comment. If there are any questions to user add them to the comment. Do not include in JIRA issue comment: "Affected Repositories", "Implementation Timeline" and any time estimations.
    - Store all context needed to continue working on this feature in confluence "$ARGUMENT AI Context" subpage under $ARGUMENT page. Treat it as an input to other claude instance. Write down all info needed to continue your work effortlessly. This will not be checked by human. 
