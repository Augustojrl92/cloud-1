PROJECT_ID := cloud-1-506415
ZONE := us-central1-c
VM_NAME := cloud-1-vm
VM_NAME_2 := cloud-1-vm-2

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
	status inventory ping ping-cloud1 ping-cloud2 check-cloud1 check-cloud2 deploy deploy-cloud1 deploy-cloud2 \
	backup restore monitoring-cloud1 health health-cloud1 \
	compose-config up down ps ps-cloud1 ps-cloud2 logs logs-cloud1 logs-cloud2 https-cloud1 \
	tools tools-build

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
	@echo ""
	@echo "Ansible:"
	@echo "  make inventory"
	@echo "  make ping"
	@echo "  make check-cloud1"
	@echo "  make check-cloud2"
	@echo "  make deploy"
	@echo "  make deploy-cloud1"
	@echo "  make deploy-cloud2"
	@echo ""
	@echo "Backups:"
	@echo "  make backup"
	@echo "  make restore"
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

tf-init:
	cd terraform && terraform init

tf-validate:
	cd terraform && terraform validate

tf-plan:
	cd terraform && terraform plan

tf-apply:
	cd terraform && terraform apply

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
