import re
# Read the current version from the Helm Chart.yaml
with open("helm-chart/Chart.yaml", "r") as f:
    content = f.read()
match = re.search(r"^version:\s*([^\s]+)", content, re.MULTILINE)
if match:
    current_version = match.group(1)
else:
    # Default to v0.0.0 if not found
    current_version = "v0.0.0"

# Strip leading 'v' if present
ver = current_version.lstrip('v')
parts = ver.split('.')
# Ensure we have Major.Minor.Patch
parts = [int(p) for p in parts] 
while len(parts) < 3:
    parts.append(0)
# Bump patch (Semantic versioning could be enhanced to bump minor/major based on commit message)
parts[2] += 1
new_version = f"v{parts[0]}.{parts[1]}.{parts[2]}"
print(new_version)