import docker
import re
import os
from collections import defaultdict

# Connect to Docker registry
client = docker.from_env()
client.login(
    username=os.environ["DOCKER_USERNAME"],
    password=os.environ["DOCKER_PASSWORD"],
    registry="docker.lakes.house"
)

# Define the base repository
base_repo = "docker.lakes.house/unityci/editor"

# Get all images
images = []
try:
    # For a real registry we would use the client.images.search, but for private registry
    # we need to list tags for the repository
    # This might require API calls specific to your registry
    # For this example, we assume we can get a list of tags
    response = client.api.get_registry_data(base_repo)
    for tag in response.get("tags", []):
        images.append(f"{base_repo}:{tag}")
except Exception as e:
    print(f"Error listing images: {e}")
    # Fallback approach or error handling

# Process images to extract Unity versions and platforms
unity_platforms = defaultdict(set)
image_map = defaultdict(dict)

pattern = re.compile(r"ubuntu-(\d+\.\d+\.\d+\w*)-(\w+)-runner")

for image in images:
    match = pattern.search(image)
    if match:
        unity_version = match.group(1)
        platform = match.group(2)
        unity_platforms[unity_version].add(platform)
        image_map[unity_version][platform] = image

# Get all unique platforms
all_platforms = set()
for platforms in unity_platforms.values():
    all_platforms.update(platforms)
all_platforms = sorted(list(all_platforms))

# Generate markdown table
markdown = "# Unity Docker Images\n\n"
markdown += "A table of available Docker images for Unity CI/CD:\n\n"
markdown += "| Unity Version |"

# Add platform headers
for platform in all_platforms:
    markdown += f" {platform} |"
markdown += "\n|"

# Add separator row
for _ in range(len(all_platforms) + 1):
    markdown += " --- |"
markdown += "\n"

# Add rows for each Unity version
for unity_version in sorted(unity_platforms.keys()):
    markdown += f"| {unity_version} |"
    
    for platform in all_platforms:
        if platform in image_map[unity_version]:
            image_name = image_map[unity_version][platform].split("/")[-1]
            markdown += f" `{image_name}` |"
        else:
            markdown += " - |"
    
    markdown += "\n"

# Write to README.md
with open("README.md", "w") as f:
    f.write(markdown)

print("README updated successfully!")