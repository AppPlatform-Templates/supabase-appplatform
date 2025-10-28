# Custom Command Creation - Lessons Learned

## What We Built

A comprehensive `/verify-fix-appspec` command that embeds all the knowledge from debugging the Supabase App Platform deployment.

### Location
`.claude/commands/verify-fix-appspec.md`

### What It Does

1. **Validates** app.yaml using `doctl apps spec validate`
2. **Detects** 8+ categories of issues
3. **Fixes** problems automatically
4. **Reports** detailed findings with explanations
5. **Re-validates** after applying fixes

## Key Lessons Embedded in the Command

### 1. The Golden Workflow
```bash
Fix app.yaml → Validate → Sync to deploy.template.yaml
```

This is the correct order! Not the other way around.

### 2. Ingress Routing Rules (THE Most Common Issue)

**What We Learned**:
```yaml
# ❌ WRONG - Causes deployment to fail
ingress:
  rules:
    - component:
        name: auth  # References worker - FAILS!
workers:
  - name: auth

# ✅ CORRECT - Ingress can only route to services
ingress:
  rules:
    - component:
        name: auth
services:
  - name: auth  # Must be a service!
```

**Key Insight**: Ingress rules can ONLY route to:
- `services` ✅
- `functions` ✅
- `static_sites` ✅
- NOT `workers` ❌

### 3. Source Type Conflicts

**What We Learned**:
```yaml
# ❌ WRONG - Can't have both
services:
  - name: app
    git:
      repo_clone_url: ...
    image:
      registry_type: DOCKER_HUB

# ✅ CORRECT - Pick one
services:
  - name: app
    image:
      registry_type: DOCKER_HUB
```

**Key Insight**: Use EITHER `git:` OR `image:`, never both.

### 4. http_port is Actually Valid!

**What We Learned**:
```yaml
# ✅ CORRECT - http_port works with Docker Hub images!
services:
  - name: studio
    image:
      registry_type: DOCKER_HUB
      registry: supabase
      repository: studio
    http_port: 3000  # This is fine!
```

**Key Insight**: Contrary to initial assumptions, `http_port` IS valid for Docker Hub images.

### 5. Workers vs Services Architecture

**What We Learned**:

| Component Type | When to Use | Can Be in Ingress? | Has HTTP Port? |
|---------------|-------------|-------------------|----------------|
| **Service** | HTTP-accessible endpoints | ✅ Yes | ✅ Yes |
| **Worker** | Internal background tasks | ❌ No | ❌ No |
| **Function** | Serverless functions | ✅ Yes | N/A |
| **Static Site** | Frontend assets | ✅ Yes | N/A |
| **Job** | One-time/scheduled tasks | ❌ No | ❌ No |

**Real Example from Supabase**:
```yaml
services:  # HTTP-accessible
  - studio      # Web dashboard
  - rest        # REST API (PostgREST)
  - auth        # GoTrue auth service
  - storage     # File storage API

workers:  # Internal-only
  - meta        # Database management (only Studio talks to it)
```

### 6. The Validation Workflow

**What We Learned**:

```bash
# Step 1: Remove spec: wrapper for validation
sed '1d; s/^  //' .do/app.yaml > /tmp/validate.yaml

# Step 2: Validate
doctl apps spec validate /tmp/validate.yaml

# Step 3: Read the error message carefully!
# It tells you EXACTLY what's wrong and where
```

**Key Insight**: Validation errors are precise. Trust them!

### 7. Common Error Patterns

From our debugging session, these are the most common issues:

1. **Component in wrong section** (worker should be service)
2. **Duplicate source definitions** (both git and image)
3. **Missing health checks** on HTTP services
4. **Port mismatches** (http_port vs actual listening port)
5. **Invalid env var scopes** for Docker images
6. **Missing SECRET type** on sensitive variables
7. **Invalid fields** (e.g., http_port on workers)
8. **Duplicate component definitions**

### 8. The Debugging Process That Worked

1. ✅ Fix `app.yaml` (it's the source of truth)
2. ✅ Validate with `doctl apps spec validate`
3. ✅ Read error messages carefully (they're accurate!)
4. ✅ Fix the actual issue (not what you think it is)
5. ✅ Re-validate until it passes
6. ✅ Sync to `deploy.template.yaml`
7. ✅ Test actual deployment

**What DIDN'T work**:
- ❌ Fixing deploy.template.yaml first
- ❌ Guessing what the issue might be
- ❌ Chasing red herrings (like removing http_port)
- ❌ Making changes without validation

## How to Use the Command

### Basic Usage

```bash
# In Claude Code, just type:
/verify-fix-appspec
```

### What Happens

1. Locates your app.yaml file (`.do/app.yaml` or `app.yaml`)
2. Runs `doctl apps spec validate`
3. Checks 8+ categories of common issues
4. Shows you what's wrong and why
5. Applies automatic fixes
6. Shows before/after diff
7. Asks for confirmation
8. Saves fixed version
9. Re-validates to confirm
10. Provides detailed report

### Example Scenario

**You have**: An app.yaml with an ingress routing to a worker

**What the command does**:
```markdown
## Issues Found

1. Ingress routing to worker component
   - Location: ingress.rules[1].component.name: "auth"
   - Impact: Deploy will fail - ingress cannot route to workers
   - Fix: Moved 'auth' from workers to services
   - Why: App Platform ingress can only route to services, functions, or static_sites

## Fixes Applied
- ✅ Moved 'auth' component from workers: to services:
- ✅ Added health_check to auth service (required for HTTP services)
- ✅ Kept http_port: 9999 (valid for Docker Hub images)
```

## How Custom Commands Work in Claude Code

### File Structure

```
.claude/
└── commands/
    ├── verify-fix-appspec.md  # The command
    └── README.md              # Documentation
```

### Command File Format

```markdown
---
description: Short description for /help
---

# Command Title

Detailed instructions that become the prompt for Claude Code.
This is what guides Claude's behavior when the command is invoked.
```

### How to Create New Commands

1. Create `.claude/commands/your-command.md`
2. Add frontmatter with description
3. Write detailed instructions
4. Include examples and edge cases
5. Save and use with `/your-command`

### What Makes a Good Command

✅ **Clear instructions** - Tell Claude exactly what to do
✅ **Domain knowledge** - Include expertise and best practices
✅ **Examples** - Show correct and incorrect patterns
✅ **Error handling** - What to do when things go wrong
✅ **Step-by-step process** - Break down complex tasks
✅ **Validation** - How to verify the work is correct

## The Knowledge Transfer

This command encapsulates:

- 🎓 **3 hours of debugging** Supabase deployment
- 🔍 **8 different error types** encountered and fixed
- 💡 **Real-world patterns** from actual App Platform usage
- ✅ **Validated solutions** that actually work
- 📚 **Best practices** from DO documentation
- 🛠️ **Automated fixes** for common issues

## Benefits

**For You**:
- Never debug the same App Spec issue twice
- Instant validation and fixing
- Confidence in deployments

**For Your Team**:
- Consistent App Spec quality
- Knowledge preserved in code
- Faster onboarding

**For Future Projects**:
- Reusable expertise
- Pattern recognition
- Continuous improvement

## Next Steps

1. **Use it**: Run `/verify-fix-appspec` on any App Platform project
2. **Improve it**: Add new patterns as you discover them
3. **Share it**: Copy to other repos that use App Platform
4. **Extend it**: Create commands for other common tasks

## Resources

- Command file: `.claude/commands/verify-fix-appspec.md`
- Documentation: `.claude/commands/README.md`
- App Spec Reference: https://docs.digitalocean.com/products/app-platform/reference/app-spec/

---

**Created**: October 2024
**Based on**: Real debugging session fixing Supabase App Platform deployment
**Location**: https://github.com/AppPlatform-Templates/supabase-appplatform
