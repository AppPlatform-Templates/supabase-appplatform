# Custom Claude Code Commands

This directory contains custom commands for working with DigitalOcean App Platform specifications.

## Available Commands

### `/verify-fix-appspec`

**Purpose**: Thoroughly verify and automatically fix DigitalOcean App Platform `app.yaml` spec files.

**What It Does**:
1. ✅ Validates spec using `doctl apps spec validate`
2. ✅ Checks 8+ categories of common issues
3. ✅ Auto-fixes problems when possible
4. ✅ Provides detailed reports with explanations
5. ✅ Shows before/after diffs
6. ✅ Re-validates after fixes

**Key Checks**:
- Ingress routing (only services/functions/static_sites, NOT workers)
- Component type mismatches (worker vs service)
- Duplicate source definitions (git + image)
- Missing required fields
- Invalid environment variable scopes
- Health check issues
- Port mismatches
- Missing secrets
- Component relationship validation
- Resource sizing recommendations

**Usage**:

```bash
# In Claude Code, just type:
/verify-fix-appspec

# Or if app.yaml is in a non-standard location:
/verify-fix-appspec path/to/app.yaml
```

**Example Output**:

```markdown
# App Spec Validation Report

## Status: ISSUES FOUND ⚠️

### Validation Results
Error: ingress rules only support services, functions, and static_sites.
seen in component name: "auth" for path: "/auth/v1"

### Issues Found
1. Ingress routing to worker component
   - Location: ingress.rules[1].component.name: "auth"
   - Impact: Deploy will fail - ingress cannot route to workers
   - Fix: Moved 'auth' from workers to services

2. Missing health check
   - Location: services[2].name: "auth"
   - Impact: Deployment may be unstable
   - Fix: Added health check on port 9999, path /health

### Fixes Applied
- Moved auth from workers to services (ingress requirement)
- Added health check to auth service
- Fixed http_port mismatch in storage service

### Manual Review Needed
- Consider upgrading to professional tier for auto-scaling
- Add SMTP configuration for email auth features

### Next Steps
1. Review changes in .do/app.yaml
2. Test deployment: doctl apps create --spec .do/app.yaml
3. Sync fixes to deploy.template.yaml
```

**Built-in Knowledge**:

The command incorporates real-world experience from:
- ✅ Building complex Supabase deployments
- ✅ Debugging ingress routing issues
- ✅ Fixing source type conflicts
- ✅ Optimizing component types
- ✅ Validating against DO App Platform constraints

**Prerequisites**:
- `doctl` CLI installed and authenticated
- `app.yaml` file exists in `.do/` or repository root

**Best Practices**:

1. **Run before every deployment** to catch issues early
2. **Review the diff** before accepting automatic fixes
3. **Test in staging** before applying to production specs
4. **Sync to deploy.template.yaml** after fixing app.yaml

## How Custom Commands Work

Custom commands are Markdown files in `.claude/commands/` that expand into prompts when you type them.

**File Structure**:
```markdown
---
description: Brief description shown in /help
---

# Command Title

Detailed instructions for Claude Code on what to do when this command is invoked.
The content becomes the prompt that guides Claude's behavior.
```

**Creating New Commands**:

1. Create a file: `.claude/commands/your-command-name.md`
2. Add frontmatter with description
3. Write detailed instructions for Claude
4. Save and commit

**Using Commands**:

```bash
# In Claude Code, type:
/your-command-name

# With arguments:
/your-command-name arg1 arg2
```

**Tips**:
- Commands run in the context of your current directory
- Claude has access to all tools (Read, Write, Edit, Bash, etc.)
- Be specific in your instructions
- Include examples and edge cases
- Document prerequisites and expected outputs

## Contributing

To improve the `/verify-fix-appspec` command:

1. Add new check patterns based on real-world issues
2. Expand the knowledge base with more examples
3. Add support for more App Platform features
4. Improve error messages and fix suggestions

## Resources

- [DigitalOcean App Platform Docs](https://docs.digitalocean.com/products/app-platform/)
- [App Spec Reference](https://docs.digitalocean.com/products/app-platform/reference/app-spec/)
- [Claude Code Documentation](https://docs.claude.com/claude-code)
