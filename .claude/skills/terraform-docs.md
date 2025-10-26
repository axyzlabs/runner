# Terraform Documentation and Analysis Skill

## Purpose
Analyze Terraform configurations, provide documentation for Terraform resources, and help debug Terraform plans. This skill uses the Terraform MCP server for accurate resource documentation.

## When to Use
- Writing Terraform configurations
- Debugging Terraform plan failures
- Understanding Terraform resource syntax
- Reviewing Terraform state changes
- Optimizing Terraform configurations

## Inputs
- **resource_type**: Terraform resource type (e.g., aws_instance, aws_s3_bucket)
- **provider**: Cloud provider (aws, azure, gcp, etc.)
- **action**: lookup, validate, plan, or format
- **config**: Terraform configuration snippet (for validation)

## Process
1. Query Terraform MCP server for resource documentation
2. Validate configuration syntax if provided
3. Analyze Terraform plan output
4. Suggest improvements and best practices
5. Format output with examples

## Outputs
- Resource documentation and syntax
- Configuration examples
- Best practices for the resource type
- Common pitfalls and how to avoid them
- Links to official Terraform documentation

## Example Usage

### Resource Documentation
```
Input: resource_type=aws_instance, action=lookup
Output: Complete aws_instance documentation with required/optional arguments
```

### Configuration Validation
```
Input: action=validate, config=<terraform snippet>
Output: Validation results with errors/warnings and suggestions
```

### Plan Analysis
```
Input: action=plan, config=<terraform config>
Output: Expected resource changes, potential issues, cost implications
```

## Error Handling
- Invalid resource types: suggest correct provider prefix
- Syntax errors: provide specific line/column information
- Missing required arguments: list all required fields
- Version conflicts: suggest compatible provider versions

## Best Practices
- Always specify provider version constraints
- Use variables for environment-specific values
- Enable state locking for team environments
- Use modules for reusable infrastructure patterns
- Tag resources consistently for cost tracking

## Notes
- This skill requires the Terraform MCP server to be configured
- Supports Terraform 1.0+ syntax
- Provider-specific features may require additional configuration
- Plan analysis requires valid Terraform configuration
