import docker
import requests
import time

# URL de Homarr
HOMARR_URL = "http://homarr:7575"

def get_containers():
    client = docker.from_env()
    return client.containers.list()

def send_to_homarr(data):
    try:
        response = requests.post(HOMARR_URL, json=data)
        response.raise_for_status()
        print("Data sent to Homarr successfully.")
    except requests.exceptions.RequestException as e:
        print(f"Error sending data to Homarr: {e}")

def main():
    while True:
        containers = get_containers()
        container_info = []
        for container in containers:
            container_info.append({
                "name": container.name,
                "image": container.image.tags[0],
                "status": container.status,
                "ports": container.ports,
                # Ajoutez d'autres informations si nécessaire
            })
        
        send_to_homarr(container_info)
        time.sleep(60)  # Envoyer les informations toutes les minutes

if __name__ == "__main__":
    main()
