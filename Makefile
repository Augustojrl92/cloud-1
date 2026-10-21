PROJECT_ID := cloud-1-506415
ZONE := us-central1-c
VM_NAME := cloud-1-vm
VM_NAME_2 := cloud-1-vm-2

# Keep Terraform providers and internal state off the Windows bind mount.
TF_DATA_DIR := /tmp/cloud1-terraform-data
export TF_DATA_DIR

ifeq ($(OS),Windows_NT)
GCLOUD_CONFIG := $(APPDATA)/gcloud
else
GCLOUD_CONFIG := $(HOME)/.config/gcloud
endif

ANSIBLE_DIR := ansible
INVENTORY := $(ANSIBLE_DIR)/inventory/hosts.ini
PLAYBOOK := $(ANSIBLE_DIR)/playbook.yml
BACKUP_PLAYBOOK := $(ANSIBLE_DIR)/backup.yml
RESTORE_PLAYBOOK := $(ANSIBLE_DIR)/restore.yml
MONITORING_PLAYBOOK := $(ANSIBLE_DIR)/monitoring.yml
HEALTH_PLAYBOOK := $(ANSIBLE_DIR)/health.yml

.PHONY: help \
	tf-init tf-validate tf-plan tf-apply \
	vm-start vm-stop vm-start-2 vm-stop-2 vm-start-all vm-stop-all vm-status \
	destroy-cloud2 recreate-cloud2 \
	status inventory ping ping-cloud1 ping-cloud2 check-cloud1 check-cloud2 deploy deploy-cloud1 deploy-cloud2 test-deployment \
	backup restore monitoring-cloud1 health health-cloud1 \
	compose-config up down ps ps-cloud1 ps-cloud2 logs logs-cloud1 logs-cloud2 https-cloud1 \
	tools tools-build evaluation test-config test-security test-containers test-container-best-practices test-orchestration test-website test-idempotency

help:
	@echo "Cloud-1 commands"
	@echo ""
	@echo "Infrastructure:"
	@echo "  make tf-init"
	@echo "  make tf-validate"
	@echo "  make tf-plan"
	@echo "  make tf-apply"
	@echo ""
	@echo "Google Cloud:"
	@echo "  make vm-start"
	@echo "  make vm-stop"
	@echo "  make vm-start-2"
	@echo "  make vm-stop-2"
	@echo "  make vm-start-all"
	@echo "  make vm-stop-all"
	@echo "  make vm-status"
	@echo "  make status"
	@echo "  make destroy-cloud2"
	@echo "  make recreate-cloud2"
	@echo ""
	@echo "Ansible:"
	@echo "  make inventory"
	@echo "  make ping"
	@echo "  make check-cloud1"
	@echo "  make check-cloud2"
	@echo "  make deploy"
	@echo "  make deploy-cloud1"
	@echo "  make deploy-cloud2"
	@echo "  make test-deployment"
	@echo ""
	@echo "Backups:"
	@echo "  make backup"
	@echo "  make restore"
	@echo ""
	@echo "Observability:"
	@echo "  make monitoring-cloud1"
	@echo ""
	@echo "Health:"
	@echo "  make health"
	@echo "  make health-cloud1"
	@echo ""
	@echo "Docker:"
	@echo "  make compose-config"
	@echo "  make up"
	@echo "  make down"
	@echo "  make ps"
	@echo "  make ps-cloud1"
	@echo "  make ps-cloud2"
	@echo "  make logs"
	@echo "  make logs-cloud1"
	@echo "  make logs-cloud2"
	@echo "  make https-cloud1"
	@echo ""
	@echo "Tools:"
	@echo "  make tools"
	@echo "  make test-config"
	@echo "  make test-security"
	@echo "  make test-containers"
	@echo "  make test-container-best-practices"
	@echo "  make test-orchestration"
	@echo "  make test-website"
	@echo "  make test-idempotency"
	@echo "  make evaluation"

tf-init:
	cd terraform && terraform init

tf-validate:
	cd terraform && terraform validate

tf-plan:
	cd terraform && terraform plan

tf-apply:
	cd terraform && terraform apply

destroy-cloud2:
	terraform -chdir=terraform destroy -target=google_compute_instance.cloud1_vm_2

recreate-cloud2:
	terraform -chdir=terraform apply -target=google_compute_instance.cloud1_vm_2

vm-start:
	gcloud compute instances start $(VM_NAME) \
		--zone $(ZONE) \
		--project $(PROJECT_ID)

vm-stop:
	gcloud compute instances stop $(VM_NAME) \
		--zone $(ZONE) \
		--project $(PROJECT_ID)

vm-start-2:
	gcloud compute instances start $(VM_NAME_2) \
		--zone $(ZONE) \
		--project $(PROJECT_ID)

vm-stop-2:
	gcloud compute instances stop $(VM_NAME_2) \
		--zone $(ZONE) \
		--project $(PROJECT_ID)

vm-start-all:
	gcloud compute instances start $(VM_NAME) $(VM_NAME_2) \
		--zone $(ZONE) \
		--project $(PROJECT_ID)

vm-stop-all:
	gcloud compute instances stop $(VM_NAME) $(VM_NAME_2) \
		--zone $(ZONE) \
		--project $(PROJECT_ID)

vm-status:
	gcloud compute instances list \
		--project $(PROJECT_ID) \
		--filter="name~'^cloud-1-vm(-2)?$$'" \
		--format="table(name,status,networkInterfaces[0].accessConfigs[0].natIP:label=EXTERNAL_IP)"

status: vm-status

inventory:
	./scripts/generate_inventory.sh

ping: inventory
	ansible cloud -i $(INVENTORY) -m ping

ping-cloud1: inventory
	ansible cloud1 -i $(INVENTORY) -m ping

ping-cloud2: inventory
	ansible cloud2 -i $(INVENTORY) -m ping

check-cloud1: inventory
	ansible cloud1 -i $(INVENTORY) -m ping

check-cloud2: inventory
	ansible cloud2 -i $(INVENTORY) -m ping

deploy: inventory
	ansible-playbook -i $(INVENTORY) $(PLAYBOOK)

deploy-cloud1: inventory
	ansible-playbook -i $(INVENTORY) $(PLAYBOOK) --limit cloud1

deploy-cloud2: inventory
	ansible-playbook -i $(INVENTORY) $(PLAYBOOK) --limit cloud2

test-deployment: inventory
	@echo "== Check cloud2 availability =="
	@grep -q '^cloud2 ' ansible/inventory/hosts.ini || { \
		echo "ERROR: cloud2 no esta disponible en el inventario"; \
		exit 1; \
	}

	@echo "== Deploy to cloud2 =="
	ansible-playbook -i ansible/inventory/hosts.ini ansible/playbook.yml --limit cloud2

	@echo "== Verify HTTPS on cloud2 =="
	ansible cloud2 -i ansible/inventory/hosts.ini -b -m shell \
		-a 'curl -kfsS https://127.0.0.1/ >/dev/null'

	@echo "== Verify WordPress installation on cloud2 =="
	ansible cloud2 -i ansible/inventory/hosts.ini -b -m shell \
		-a 'cd /opt/cloud-1 && docker compose --profile cli run --rm wordpress-cli wp core is-installed --path=/var/www/html --allow-root'

	@echo "== Verify containers on cloud2 =="
	ansible cloud2 -i ansible/inventory/hosts.ini -b -m shell \
		-a 'docker ps --format "{% raw %}{{.Names}} {{.Status}}{% endraw %}"'

	@echo "== Deployment test OK =="

backup: inventory
	ansible-playbook -i $(INVENTORY) $(BACKUP_PLAYBOOK)

restore: inventory
	ansible-playbook -i $(INVENTORY) $(RESTORE_PLAYBOOK)

monitoring-cloud1: inventory
	ansible-playbook -i $(INVENTORY) $(MONITORING_PLAYBOOK)

health: inventory
	ansible-playbook -i $(INVENTORY) $(HEALTH_PLAYBOOK)

health-cloud1: inventory
	ansible-playbook -i $(INVENTORY) $(HEALTH_PLAYBOOK) --limit cloud1

compose-config: inventory
	ansible cloud -i $(INVENTORY) -b -m shell \
		-a "cd /opt/cloud-1 && docker compose config"

up: inventory
	ansible cloud -i $(INVENTORY) -b -m shell \
		-a "cd /opt/cloud-1 && docker compose up -d"

down: inventory
	ansible cloud -i $(INVENTORY) -b -m shell \
		-a "cd /opt/cloud-1 && docker compose down"

ps: inventory
	ansible cloud -i $(INVENTORY) -b -a "docker ps"

ps-cloud1: inventory
	ansible cloud1 -i $(INVENTORY) -b -a "docker ps"

ps-cloud2: inventory
	ansible cloud2 -i $(INVENTORY) -b -a "docker ps"

logs: inventory
	ansible cloud -i $(INVENTORY) -b -m shell \
		-a "cd /opt/cloud-1 && docker compose logs --tail=100"

logs-cloud1: inventory
	ansible cloud1 -i $(INVENTORY) -b -m shell \
		-a "cd /opt/cloud-1 && docker compose logs --tail=100"

logs-cloud2: inventory
	ansible cloud2 -i $(INVENTORY) -b -m shell \
		-a "cd /opt/cloud-1 && docker compose logs --tail=100"

https-cloud1:
	curl -k -I https://136.113.10.158

tools-build:
	docker build -t cloud1-tools -f tools/Dockerfile .

tools: tools-build
	docker run --rm -it \
		-v "$(PWD):/workspace" \
		-v "$(GCLOUD_CONFIG):/root/.config/gcloud" \
		-v "$(HOME)/.ssh:/host-ssh:ro" \
		cloud1-tools \
		bash -lc 'mkdir -p /root/.ssh && \
		          cp /host-ssh/google_compute_engine /root/.ssh/google_compute_engine && \
		          cp /host-ssh/google_compute_engine.pub /root/.ssh/google_compute_engine.pub && \
		          chmod 700 /root/.ssh && \
		          chmod 600 /root/.ssh/google_compute_engine && \
		          chmod 644 /root/.ssh/google_compute_engine.pub && \
		          exec bash'

evaluation:
	$(MAKE) test-config
	$(MAKE) test-security
	$(MAKE) test-containers
	$(MAKE) test-orchestration
	$(MAKE) test-website
	$(MAKE) test-idempotency
	$(MAKE) test-container-best-practices

test-config:
	@echo "== Terraform init =="
	terraform -chdir=terraform init -backend=false

	@echo "== Terraform validate =="
	terraform -chdir=terraform validate

	@echo "== Ansible syntax check =="
	ansible-playbook -i ansible/inventory/hosts.ini ansible/playbook.yml --syntax-check
	ansible-playbook -i ansible/inventory/hosts.ini ansible/backup.yml --syntax-check
	ansible-playbook -i ansible/inventory/hosts.ini ansible/restore.yml --syntax-check
	ansible-playbook -i ansible/inventory/hosts.ini ansible/monitoring.yml --syntax-check
	ansible-playbook -i ansible/inventory/hosts.ini ansible/health.yml --syntax-check

	@echo "== Configuration tests OK =="

test-security:
	@echo "== Secrets management =="
	@if git ls-files docker/.env | grep -q .; then \
		echo "ERROR: docker/.env esta versionado"; \
		exit 1; \
	else \
		echo "OK: docker/.env no esta versionado"; \
	fi

	@echo "== Database exposure =="
	@if grep -A 20 '^  mariadb:' docker/docker-compose.yml | grep -q '3306:3306'; then \
		echo "ERROR: MariaDB publica 3306"; \
		exit 1; \
	else \
		echo "OK: MariaDB no publica 3306"; \
	fi

	@echo "== WordPress exposure =="
	@if grep -A 25 '^  wordpress:' docker/docker-compose.yml | grep -qE '^[[:space:]]*-[[:space:]]*"?[0-9]+:[0-9]+'; then \
		echo "ERROR: WordPress publica un puerto al host"; \
		exit 1; \
	else \
		echo "OK: WordPress no publica puertos al host"; \
	fi

	@echo "== phpMyAdmin exposure =="
	@if grep -A 25 '^  phpmyadmin:' docker/docker-compose.yml | grep -qE '^[[:space:]]*-[[:space:]]*"?[0-9]+:[0-9]+'; then \
		echo "ERROR: phpMyAdmin publica un puerto al host"; \
		exit 1; \
	else \
		echo "OK: phpMyAdmin no publica puertos al host"; \
	fi

	@echo "== Nginx web ports =="
	@grep -A 30 '^  nginx:' docker/docker-compose.yml | grep -q '80:80' || { echo "ERROR: Nginx no publica 80"; exit 1; }
	@grep -A 30 '^  nginx:' docker/docker-compose.yml | grep -q '443:443' || { echo "ERROR: Nginx no publica 443"; exit 1; }

	@echo "== Security tests OK =="

test-container-best-practices:
	@echo "== Official images =="
	@grep -q 'image: mariadb:' docker/docker-compose.yml || { \
		echo "ERROR: MariaDB no usa una imagen declarada"; \
		exit 1; \
	}
	@grep -q 'image: wordpress:' docker/docker-compose.yml || { \
		echo "ERROR: WordPress no usa una imagen declarada"; \
		exit 1; \
	}
	@grep -q 'image: phpmyadmin:' docker/docker-compose.yml || { \
		echo "ERROR: phpMyAdmin no usa una imagen declarada"; \
		exit 1; \
	}
	@grep -q 'image: nginx:' docker/docker-compose.yml || { \
		echo "ERROR: Nginx no usa una imagen declarada"; \
		exit 1; \
	}

	@echo "== No unnecessary custom builds =="
	@if grep -qE '^[[:space:]]*build:' docker/docker-compose.yml; then \
		echo "INFO: hay builds custom; revisar Dockerfiles"; \
	else \
		echo "OK: se usan imagenes preconstruidas"; \
	fi

	@echo "== Restart policies =="
	@grep -q 'restart: unless-stopped' docker/docker-compose.yml || { \
		echo "ERROR: faltan restart policies"; \
		exit 1; \
	}

	@echo "== Healthchecks =="
	@grep -q 'healthcheck:' docker/docker-compose.yml || { \
		echo "ERROR: no hay healthchecks"; \
		exit 1; \
	}

	@echo "== Persistent volumes =="
	@grep -q 'mariadb_data:' docker/docker-compose.yml || { \
		echo "ERROR: falta volumen de MariaDB"; \
		exit 1; \
	}
	@grep -q 'wordpress_data:' docker/docker-compose.yml || { \
		echo "ERROR: falta volumen de WordPress"; \
		exit 1; \
	}

	@echo "== Image tags =="
	@if grep -E '^[[:space:]]*image:.*:latest$$' docker/docker-compose.yml; then \
		echo "WARNING: hay imagenes con :latest; funciona, pero reduce reproducibilidad"; \
	else \
		echo "OK: imagenes versionadas"; \
	fi

	@echo "== Container best-practices tests OK =="

test-containers: inventory
	@echo "== Required containers =="
	ansible cloud1 -i ansible/inventory/hosts.ini -b -m shell \
		-a 'docker ps --format "{% raw %}{{.Names}}{% endraw %}" | grep -q "^cloud1_mariadb$$"'

	ansible cloud1 -i ansible/inventory/hosts.ini -b -m shell \
		-a 'docker ps --format "{% raw %}{{.Names}}{% endraw %}" | grep -q "^cloud1_wordpress$$"'

	ansible cloud1 -i ansible/inventory/hosts.ini -b -m shell \
		-a 'docker ps --format "{% raw %}{{.Names}}{% endraw %}" | grep -q "^cloud1_phpmyadmin$$"'

	ansible cloud1 -i ansible/inventory/hosts.ini -b -m shell \
		-a 'docker ps --format "{% raw %}{{.Names}}{% endraw %}" | grep -q "^cloud1_nginx$$"'

	@echo "== Persistent volumes =="
	ansible cloud1 -i ansible/inventory/hosts.ini -b -m shell \
		-a 'docker volume ls | grep -q "mariadb_data"'

	ansible cloud1 -i ansible/inventory/hosts.ini -b -m shell \
		-a 'docker volume ls | grep -q "wordpress_data"'

	@echo "== Docker network =="
	ansible cloud1 -i ansible/inventory/hosts.ini -b -m shell \
		-a 'docker network ls | grep -q "cloud1_network"'

	@echo "== Containers tests OK =="

test-orchestration: inventory
	@echo "== Docker Compose stack =="
	ansible cloud1 -i ansible/inventory/hosts.ini -b -m shell \
		-a 'cd /opt/cloud-1 && docker compose ps'

	@echo "== Restart Nginx independently =="
	ansible cloud1 -i ansible/inventory/hosts.ini -b -m shell \
		-a 'cd /opt/cloud-1 && docker compose restart nginx'

	@echo "== Verify Nginx after restart =="
	ansible cloud1 -i ansible/inventory/hosts.ini -b -m shell \
		-a 'sleep 3 && curl -kfsS https://127.0.0.1/ >/dev/null'

	@echo "== Orchestration tests OK =="

test-website: inventory
	@echo "== WordPress local HTTPS =="
	ansible cloud1 -i ansible/inventory/hosts.ini -b -m shell \
		-a 'curl -kfsS -o /dev/null -w "%{http_code}\n" https://127.0.0.1/ | grep -q "^200$$"'

	@echo "== Multiple requests =="
	ansible cloud1 -i ansible/inventory/hosts.ini -b -m shell \
		-a 'for i in 1 2 3 4 5; do curl -kfsS https://127.0.0.1/ >/dev/null || exit 1; done'

	@echo "== WordPress installation =="
	ansible cloud1 -i ansible/inventory/hosts.ini -b -m shell \
		-a 'cd /opt/cloud-1 && docker compose --profile cli run --rm wordpress-cli wp core is-installed'

	@echo "== Website tests OK =="

test-idempotency: inventory
	@echo "== First deployment =="
	ansible-playbook -i ansible/inventory/hosts.ini ansible/playbook.yml --limit cloud1

	@echo "== Second deployment =="
	ansible-playbook -i ansible/inventory/hosts.ini ansible/playbook.yml --limit cloud1

	@echo "== Verify application after second deployment =="
	ansible cloud1 -i ansible/inventory/hosts.ini -b -m shell \
		-a 'curl -kfsS https://127.0.0.1/ >/dev/null'

	@echo "== Verify container health =="
	ansible cloud1 -i ansible/inventory/hosts.ini -b -m shell \
		-a 'docker ps --format "{% raw %}{{.Names}} {{.Status}}{% endraw %}"'

	@echo "== Idempotency test OK =="
