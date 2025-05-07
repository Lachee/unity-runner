#!/usr/bin/env python3

import argparse
import requests
import json
import sys
import os
import re
from urllib.parse import urlparse


def get_docker_hub_tags(repository, limit=1000):
    """
    Get tags for a Docker Hub repository
    """
    url = f"https://hub.docker.com/v2/repositories/{repository}/tags"
    params = {"page_size": limit}
    
    # Check for Docker Hub credentials in environment variables
    username = os.getenv('DOCKER_USERNAME')
    password = os.getenv('DOCKER_PASSWORD')
    
    # Create session for potential authentication
    session = requests.Session()
    
    # Authenticate if credentials are provided
    if username and password:
        auth_url = "https://hub.docker.com/v2/users/login/"
        auth_data = {"username": username, "password": password}
        
        try:
            auth_response = session.post(auth_url, json=auth_data)
            auth_response.raise_for_status()
            # Token is automatically stored in the session cookies
        except requests.exceptions.RequestException as e:
            print(f"Warning: Docker Hub authentication failed: {e}")
            # Continue without authentication
    
    all_tags = []
    
    while url:
        response = session.get(url, params=params)
        if response.status_code != 200:
            print(f"Error: Unable to fetch tags. Status code: {response.status_code}")
            print(f"Response: {response.text}")
            sys.exit(1)
        
        data = response.json()
        all_tags.extend([tag["name"] for tag in data["results"]])
        
        # Get next page URL if it exists
        url = data.get("next")
        # Clear params since the next URL already includes them
        params = {}
        
    return all_tags

def get_private_registry_tags(registry, repository):
    """
    Get tags for a repository in a private registry
    """
    # Check for registry credentials in environment variables
    username = os.getenv('DOCKER_USERNAME')
    password = os.getenv('DOCKER_PASSWORD')
    
    # Ensure registry URL starts with https://
    registry_url = registry if registry.startswith(('http://', 'https://')) else f'https://{registry}'

    # Try to get an auth token first (token-based auth)
    headers = {}
    url = f"{registry_url}/v2/{repository}/tags/list"
    
    # Make the request with appropriate authentication
    if username and password:
        # Use basic auth if we have credentials but no token
        response = requests.get(url, headers=headers, auth=(username, password))
    else:
        # Use token auth or no auth
        response = requests.get(url, headers=headers)
    
    if response.status_code != 200:
        print(f"Error: Unable to fetch tags. Status code: {response.status_code}")
        print(f"Response: {response.text}")
        sys.exit(1)
    
    data = response.json()
    return data.get("tags", [])

def main():
    parser = argparse.ArgumentParser(description="Get all tags for a Docker image")
    parser.add_argument("image", help="Docker image name (e.g., 'library/ubuntu' or 'nginx')")
    parser.add_argument("--registry", help="Registry URL for private registry (can also set DOCKER_REGISTRY env var)", default=None)
    parser.add_argument("--limit", type=int, help="Maximum number of tags to retrieve (Docker Hub only)", default=1000)
    parser.add_argument("--output", help="Output file path (default: stdout)")
    args = parser.parse_args()
    
    # Check for registry in environment variable if not specified in args
    registry = args.registry or os.getenv('DOCKER_REGISTRY')
    repository = args.image

    if registry:
        print(f"Fetching tags for {repository} from {registry}...")
        tags = get_private_registry_tags(registry, repository)
    else:
        print(f"Fetching tags for {repository} from Docker Hub...")
        tags = get_docker_hub_tags(repository, args.limit)
    
    # Sort tags
    tags.sort()

    versions={}

    pattern = re.compile(r"(\w+)-(\d+\.\d+\.\d+\w*)-(\w+)-runner")
    for tag in tags:
        matches = pattern.match(tag)
        if matches:
            [ image_os, version, component ] = matches.groups()
            if version not in versions:
                versions[version] = {}
            versions[version][component] = tag

    # Get all unique components across all versions
    print(versions)
    all_components = set()
    for version_components in versions.values():
        all_components.update(version_components.keys())
    all_components = sorted(list(all_components))

    # Create markdown table header with components as columns
    markdown = "| unity |"
    for component in all_components:
        markdown += f" {component} |"
    markdown += "\n|---------|" + "----------|" * len(all_components) + "\n"

    for version in sorted(versions.keys()):
        markdown += f"| {version} |"
        for component in all_components:
            tag = versions[version].get(component, "")
            markdown += f" {tag} |"
        markdown += "\n"

    # Read existing README.md
    print("Updating README")
    readme_path = "README.md"
    if os.path.exists(readme_path):
        with open(readme_path, 'r') as f:
            content = f.read()
        
        # Replace content between markers
        pattern = r'(<!-- table -->).*(<!-- /table -->)'
        new_content = re.sub(pattern, r'\1\n' + markdown + r'\2', content, flags=re.DOTALL)
        
        # Write back to README.md
        with open(readme_path, 'w') as f:
            f.write(new_content)

    print("Done!")

if __name__ == "__main__":
    # Print environment variable usage information
    if len(sys.argv) == 1 or (len(sys.argv) == 2 and sys.argv[1] in ['-h', '--help']):
        print("\nEnvironment Variables:")
        print("  DOCKER_REGISTRY    - URL of private Docker registry")
        print("  DOCKER_USERNAME   - Username")
        print("  DOCKER_PASSWORD - Password")
        print("\nExample:")
        print("  export DOCKER_REGISTRY=https://registry.example.com")
        print("  export DOCKER_USERNAME=username")
        print("  export DOCKER_PASSWORD=password")
        print("  python docker_image_tags.py myproject/api\n")
    
    main()