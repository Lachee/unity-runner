import os
import re
import requests
import base64
import json

DOCKER_REGISTRY = os.getenv('DOCKER_REGISTRY')
DOCKER_USERNAME = os.getenv('DOCKER_USERNAME')
DOCKER_PASSWORD = os.getenv('DOCKER_PASSWORD')
IMAGE =  os.getenv('IMAGE')

README_PATH="README.md"
DOCKERHUB_REGISTRY = "registry-1.docker.io"

def format_bytes(size_bytes : int) -> str:
    for unit in ['B', 'KB', 'MB', 'GB', 'TB']:
        if size_bytes < 1024.0:
            human_size = f"{size_bytes:.2f} {unit}"
            break
        size_bytes /= 1024.0
    return human_size
    
def get_tags_with_size(registry : str, authorization : str, repository : str) -> list[object]:
    url = f"https://{registry}/v2/{repository}/tags/list"
    headers = {
        "Authorization": f"{authorization}",
        "Accept": "application/vnd.oci.image.manifest.v1+json, application/vnd.docker.distribution.manifest.v2+json"
    }

    print(f"Querying {url}...")
    resp = requests.get(url, headers=headers)
    resp.raise_for_status()
    all_tags = resp.json()['tags']
    tags = []
    for t in all_tags:
        url = f"https://{registry}/v2/{repository}/manifests/{t}"
        print(f"- {t} looking up {url}...")
        resp = requests.get(url, headers=headers)
        resp.raise_for_status()
        layers = resp.json()['layers']
        tag = {}
        tag['name'] = t
        tag['registry'] = registry
        tag['size'] = sum(layer['size'] for layer in  layers)
        tag['layers'] = layers
        tags.append(tag)

    return tags

def login_dockerhub(username : str, password : str, forRepository : str) -> str:
    # Get token for Docker Hub API
    auth_url = "https://auth.docker.io/token"
    service = "registry.docker.io"
    scope = f"repository:{forRepository}:pull"
    params = {"service": service, "scope": scope}
    if username and password:
        resp = requests.get(auth_url, params=params, auth=(username, password))
    else:
        resp = requests.get(auth_url, params=params)
    resp.raise_for_status()
    token = resp.json()["token"]
    return f"Bearer {token}"

def login_registry(username : str, password : str) -> str:
    credentials = f"{username}:{password}"
    encoded_credentials = base64.b64encode(credentials.encode()).decode()
    return f"Basic {encoded_credentials}"

def create_label(repository: str, tag : object) -> str:
    name = tag['name']
    registry = tag['registry']
    size = format_bytes(tag['size'])
    link = f"https://{registry}/repo/{repository}/tag/{name}"
    if registry == DOCKERHUB_REGISTRY:
        link = f"https://hub.docker.com/layers/{repository}/{name}"
    return f"[🐳 View]({link})<br>📦 {size}"

def create_table(repository : str, tags : list[object]) -> str:
    markdown : str = ""
    
    versions : dict[str, dict[str, str]] = {}
    all_modules : set[str] = set()

    # Build a table of versions
    pattern = re.compile(r"(?P<os>\w+)(?P<version>-\d+\.\d+\.\d+\w*)(?P<modules>-[a-zA-Z-0-9]+)?-runner")
    for tag in tags:
        matches = pattern.match(tag['name'])
        os = matches.group("os").strip('-')
        version = matches.group("version").strip('-')
        modules = matches.group("modules").strip('-') if matches.group('modules') else "all"
        all_modules.add(modules)
        if version not in versions:
            versions[version] = {}
        versions[version][modules] = create_label(repository, tag)

    # Print the table heading
    sorted_mods = sorted([m for m in all_modules if m])
    markdown += f"|Unity|{'|'.join(sorted_mods)}|\n"
    markdown += f"|-----|{'|'.join('-' * len(m) for m in sorted_mods)}|\n"

    # For each item, check each available module and see if this version has that available.
    for ver, mods in versions.items():
        row = [ mods[mod] if mod in mods else '❌' for mod in sorted_mods ]
        markdown += f"|{ver}|{'|'.join(row)}|\n"

    return markdown

def replace_readme_table(readme : str, table : str) -> str:
    pattern = r"(<!-- table -->).*(<!-- /table -->)"
    return re.sub(pattern, r'\1\n' + table + r'\2', readme, flags=re.DOTALL)

def main():
    auth_token : str
    registry : str

    if DOCKER_REGISTRY:
        registry = DOCKER_REGISTRY
        auth_token = login_registry(DOCKER_USERNAME, DOCKER_PASSWORD)
    else:
        registry = DOCKERHUB_REGISTRY
        auth_token = login_dockerhub(DOCKER_USERNAME, DOCKER_PASSWORD, IMAGE)

    print('Fetching Tags...')
    tags = get_tags_with_size(registry, auth_token, IMAGE)

    print('Writing Readme...')
    table = create_table(IMAGE, tags)
    if os.path.exists(README_PATH):
        with open(README_PATH, "r", encoding='utf-8') as f:
            readme = f.read()
        with open(README_PATH, "w", encoding='utf-8') as f:
            f.write(replace_readme_table(readme, table))


if __name__ == "__main__":
    main()
