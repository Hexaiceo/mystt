# Fix the Feature/Bug Command

Fix solution based on latest JIRA issue comment.

## Instructions

Follow this systematic approach to fix a feature: **$ARGUMENT**
**$ARGUMENT** Can be provided only as a issue name in JIRA like SUPP-1234, SUPP-14566 etc.

1. **Gather Info**
    - Gather info about feature from "$ARGUMENT AI Context" confluence subpage - this is a context created by other claude instance to allow you to continue work on the same feature with additional user input.
    - If JIRA issue $ARGUMENT has "AI-Implemented" label - stop processing IMMEDIATELY and tell user, that this issue is already closed and done.
    - Get only the latest comment from JIRA issue $ARGUMENT - use is at a input to fix the feature already implemented by this JIRA issue. Information in comment is more important than issue description, in case of conflict - it takes priority. Pass this to @workflow-orchestrator to prepare fix plan, add context from confluence page. 

2. **Fix Implementation**
    - Do not include on page and do not perform: "Performance Optimization Strategy", "Accessibility & UX Considerations", "Implementation Phases", "Risk Management", "Success Metrics", "Recommendations".
    - Implement changes according to fix plan - remember to work on branches named the same as $ARGUMENT - so you'll continue work on the same feature.
    - If required - update confluence page and subpages (do not change pages names) created for this issue under $ARGUMENT confluence page. 
    - Update "$ARGUMENT AI Context" confluence subpage with current context, so in case of a need of additional changes - you can continue the work.

3. **Summarization**
    - After implementing the fix - put very short summary (only information regarding fix) in comment in JIRA.
