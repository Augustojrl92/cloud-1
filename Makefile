PROJECT_ID := cloud-1-506415
ZONE := us-central1-c
VM_NAME := cloud-1-vm

ANSIBLE_DIR := ansible
INVENTORY := $(ANSIBLE_DIR)/inventory/hosts.ini
PLAYBOOK := $(ANSIBLE_DIR)/playbook.yml

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
	@echo "  make ping"
	@echo "  make deploy"
	@echo ""
	@echo "Docker:"
	@echo "  make compose-config"
	@echo "  make up"
	@echo "  make down"
	@echo "  make ps"
	@echo "  make logs"

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

ping:
	ansible all -i $(INVENTORY) -m ping

deploy:
	ansible-playbook -i $(INVENTORY) $(PLAYBOOK)

compose-config:
	ansible cloud -i $(INVENTORY) -b -m shell \
		-a "cd /opt/cloud-1 && docker compose config"

up:
	ansible cloud -i $(INVENTORY) -b -m shell \
		-a "cd /opt/cloud-1 && docker compose up -d"

down:
	ansible cloud -i $(INVENTORY) -b -m shell \
		-a "cd /opt/cloud-1 && docker compose down"

ps:
	ansible cloud -i $(INVENTORY) -b -a "docker ps"

logs:
	ansible cloud -i $(INVENTORY) -b -m shell \
		-a "cd /opt/cloud-1 && docker compose logs --tail=100"
