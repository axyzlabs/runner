# AWS Documentation Lookup Skill

## Purpose
Query AWS documentation and best practices for various AWS services. This skill leverages the AWS Knowledge Base MCP server to provide accurate, up-to-date AWS documentation.

## When to Use
- Looking up AWS service documentation
- Understanding AWS best practices
- Finding AWS CLI commands and syntax
- Researching AWS service limits and quotas
- Learning about AWS security features

## Inputs
- **service**: AWS service name (e.g., EC2, S3, RDS, Lambda)
- **topic**: Specific topic or feature (optional)
- **region**: AWS region for region-specific information (optional)

## Process
1. Query AWS documentation MCP server for the specified service
2. Filter results based on topic if provided
3. Format documentation with examples and links
4. Include related services and best practices
5. Provide AWS CLI command examples where applicable

## Outputs
- Service overview and description
- Key features and capabilities
- Best practices and security recommendations
- AWS CLI command examples
- Links to official AWS documentation
- Related AWS services

## Example Usage

### Basic Service Lookup
```
Input: service=EC2
Output: EC2 documentation including instance types, pricing, networking, security groups
```

### Specific Feature Lookup
```
Input: service=S3, topic=versioning
Output: S3 versioning documentation, configuration examples, best practices
```

### Region-Specific Information
```
Input: service=RDS, region=us-east-1
Output: RDS documentation with us-east-1 availability and limitations
```

## Error Handling
- If service is not recognized, suggest similar service names
- If documentation is unavailable, provide links to AWS console
- Handle network timeouts gracefully with cached responses

## Notes
- This skill requires the AWS documentation MCP server to be configured
- Results are based on publicly available AWS documentation
- For proprietary or internal AWS documentation, configure appropriate credentials
