# Role-Based Claude Agents & Commands

This document maps available Claude agents and commands to specific professional roles, helping team members quickly identify which tools are most relevant to their responsibilities.

---

## Business Analyst

### Agents
- **business-analyst.md** - Expert business analyst specializing in requirements gathering, process improvement, and data-driven decision making
- **workflow-orchestrator.md** - Expert workflow orchestrator specializing in complex process design and business process automation
- **technical-writer.md** - Expert technical writer specializing in clear, accurate documentation and content creation

### Commands
- **issue-initialize-work.md** - Create confluence structure to initialize work on JIRA issue (requirements gathering and planning)
- **issue-closure.md** - Finalize working on feature/bug with documentation and summary

### MCP Servers
- **mcp-atlassian** (`docker-atlassian.json`) - For JIRA issue tracking and Confluence documentation management
  - Enables reading/writing JIRA issues, creating Confluence pages, and managing project documentation

---

## Software Developer

### Agents

#### General Development
- **code-reviewer.md** - Expert code reviewer specializing in code quality, security vulnerabilities, and best practices
- **debugger.md** - Expert debugger specializing in complex issue diagnosis and root cause analysis
- **refactoring-specialist.md** - Expert refactoring specialist mastering safe code transformation techniques
- **dependency-manager.md** - Expert dependency manager specializing in package management and security auditing
- **git-workflow-manager.md** - Expert Git workflow manager specializing in branching strategies and team collaboration

#### Language-Specific Agents

##### Java
- **java-architect.md** - Senior Java architect specializing in enterprise-grade applications and Spring ecosystem
- **java_8.md** - Java 8 specialist (lambda expressions, Stream API, functional programming)
- **java_11.md** - Java 11 LTS specialist (HTTP Client API, modular architecture)
- **java_17.md** - Java 17 LTS specialist (sealed classes, records, pattern matching)
- **java_21.md** - Java 21 LTS specialist (virtual threads, pattern matching for switch)
- **java_25.md** - Java 25 LTS specialist (primitive pattern matching, flexible constructors)

##### JavaScript/TypeScript
- **javascript-pro.md** - Expert JavaScript developer specializing in modern ES2023+ features
- **typescript-pro.md** - Expert TypeScript developer specializing in advanced type system usage
- **nextjs-developer.md** - Expert Next.js developer mastering Next.js 14+ with App Router

##### React
- **react-specialist.md** - Expert React specialist mastering React 18+ with modern patterns
- **react_15_specialist.md** - React 15 specialist (document.createElement rendering, SVG support)
- **react_16_specialist.md** - React 16 specialist (Fiber architecture, Error Boundaries)
- **react_17_specialist.md** - React 17 specialist (new JSX transform, event delegation changes)
- **react_18_specialist.md** - React 18 specialist (concurrent rendering, automatic batching)
- **react_19_specialist.md** - React 19 specialist (React Compiler, Server Components)
- **react-native-specialist.md** - React Native specialist for cross-platform mobile development

##### Other Languages
- **kotlin-specialist.md** - Expert Kotlin specialist mastering Kotlin 2.0+ with multiplatform support
- **ada-specialist.md** - Expert Ada specialist mastering Ada 2012/2022 with safety-critical systems

### Commands
- **issue-initialize-work.md** - Create confluence structure to initialize work on JIRA issue
- **issue-handle.md** - Handle the changes proposed in JIRA issue (implementation phase)
- **issue-fix.md** - Fix solution based on latest JIRA issue comment
- **issue-closure.md** - Finalize working on feature/bug with commit and documentation

### MCP Servers
- **mcp-atlassian** (`docker-atlassian.json`) - For JIRA issue tracking and Confluence documentation
  - Enables reading/writing JIRA issues, adding comments, updating issue status, and managing documentation
- **GitLab communication server** (`npx-gitlab.json`) - For GitLab repository management and CI/CD
  - Enables code repository operations, merge requests, pipeline monitoring, and version control integration

---

## Tester

### Agents
- **test-automator.md** - Expert test automation engineer specializing in building robust test frameworks
- **debugger.md** - Expert debugger specializing in complex issue diagnosis and root cause analysis
- **code-reviewer.md** - Expert code reviewer for quality assurance and security vulnerability detection

### Commands
- **issue-fix.md** - Fix solution based on test feedback and JIRA comments
- **issue-handle.md** - Verify implementation during the verification phase

### MCP Servers
- **mcp-atlassian** (`docker-atlassian.json`) - For JIRA defect tracking and test documentation
  - Enables reporting bugs, tracking test results, updating issue status, and documenting test cases
- **GitLab communication server** (`npx-gitlab.json`) - For accessing test pipelines and CI/CD results
  - Enables monitoring test pipeline execution, reviewing test results, and tracking automated test runs

---

## Software Architect

### Agents

#### Architecture & Design
- **software-architect.md** - Expert software architect specializing in system design and architectural patterns
- **architect-reviewer.md** - Expert architecture reviewer for design validation and technical decision assessment
- **api-designer.md** - API architecture expert designing scalable, developer-friendly interfaces
- **microservices-architect.md** - Distributed systems architect for scalable microservice ecosystems

#### Specialized Architecture
- **java-architect.md** - Senior Java architect for enterprise-grade applications
- **nextjs-developer.md** - Next.js full-stack architecture specialist

#### Quality & Compliance
- **compliance-auditor.md** - Expert compliance auditor specializing in regulatory frameworks and security standards
- **secuirty-auditor.md** - Expert security auditor for comprehensive security assessments

### Commands
- **issue-initialize-work.md** - Create architectural plans and technical specifications for JIRA issues

### MCP Servers
- **mcp-atlassian** (`docker-atlassian.json`) - For architecture documentation and design specifications
  - Enables creating architecture pages in Confluence, tracking design decisions in JIRA, and documenting technical specifications

---

## DevOps Engineer

### Agents

#### Infrastructure & Deployment
- **deployment-engineer.md** - Expert deployment engineer specializing in CI/CD pipelines and deployment strategies
- **kubernetes-specialist.md** - Expert Kubernetes specialist mastering container orchestration
- **build-engineer.md** - Expert build engineer specializing in build system optimization

#### Management & Operations
- **dependency-manager.md** - Expert dependency manager for package management and security auditing
- **git-workflow-manager.md** - Expert Git workflow manager for branching strategies and automation
- **workflow-orchestrator.md** - Expert workflow orchestrator for complex process automation

#### Security & Compliance
- **secuirty-auditor.md** - Expert security auditor for infrastructure security assessments
- **compliance-auditor.md** - Expert compliance auditor for regulatory frameworks

### Commands
- **issue-closure.md** - Finalize deployment and push changes to repositories

### MCP Servers
- **GitLab communication server** (`npx-gitlab.json`) - For GitLab repository and pipeline management
  - Enables managing repositories, monitoring CI/CD pipelines, configuring deployments, and tracking build status
- **kubernetes** (`npx-kubernetes.json`) - For Kubernetes cluster management and deployments
  - Enables managing pods, services, deployments, configmaps, and monitoring cluster resources
- **mcp-jenkins** (`uvx-jenkins.json`) - For Jenkins CI/CD pipeline automation
  - Enables managing Jenkins jobs, monitoring builds, triggering deployments, and accessing build logs
- **mcp-atlassian** (`docker-atlassian.json`) - For deployment documentation and release tracking
  - Enables documenting deployment procedures, tracking release notes, and managing deployment-related JIRA issues
