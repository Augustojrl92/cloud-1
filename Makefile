PROJECT_ID := cloud-1-506415
ZONE := us-central1-c
VM_NAME := cloud-1-vm

ifeq ($(OS),Windows_NT)
GCLOUD_CONFIG := $(APPDATA)/gcloud
else
GCLOUD_CONFIG := $(HOME)/.config/gcloud
endif

ANSIBLE_DIR := ansible
INVENTORY := $(ANSIBLE_DIR)/inventory/hosts.ini
PLAYBOOK := $(ANSIBLE_DIR)/playbook.yml

.PHONY: inventory tools tools-build

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
	@echo "  make vm-status"
	@echo ""
	@echo "Ansible:"
	@echo "  make inventory"
	@echo "  make ping"
	@echo "  make deploy"
	@echo ""
	@echo "Docker:"
	@echo "  make compose-config"
	@echo "  make up"
	@echo "  make down"
	@echo "  make ps"
	@echo "  make logs"
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

vm-status:
	gcloud compute instances list \
		--project $(PROJECT_ID) \
		--filter="name=$(VM_NAME)" \
		--format="table(name,status,networkInterfaces[0].accessConfigs[0].natIP:label=EXTERNAL_IP)"

inventory:
	./scripts/generate_inventory.sh

ping: inventory
	ansible all -i $(INVENTORY) -m ping

deploy: inventory
	ansible-playbook -i $(INVENTORY) $(PLAYBOOK)

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

logs: inventory
	ansible cloud -i $(INVENTORY) -b -m shell \
		-a "cd /opt/cloud-1 && docker compose logs --tail=100"

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
