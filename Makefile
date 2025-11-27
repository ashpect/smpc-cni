CLUSTER_NAME1?=cni1
CLUSTER_NAME2?=cni2
CLUSTER_NAME3?=cni3
CLUSTER_NAME4?=cni4
CNI_NAME1?=cni1
CNI_NAME2?=cni2
CNI_NAME3?=cni3
CNI_NAME4?=cni4
CONF_FILE1?=10-cni1.conf
CONF_FILE2?=10-cni2.conf
CONF_FILE3?=10-cni3.conf
CONF_FILE4?=10-cni4.conf

CLUSTERS := ${CLUSTER_NAME1} ${CLUSTER_NAME2} ${CLUSTER_NAME3} ${CLUSTER_NAME4}
CNI_NAMES := ${CNI_NAME1} ${CNI_NAME2} ${CNI_NAME3} ${CNI_NAME4}
CONF_FILES := ${CONF_FILE1} ${CONF_FILE2} ${CONF_FILE3} ${CONF_FILE4}

# make cluster
# make cni
# make load-images
# make node-pods
# make connect-clusters
# make orch-pods

.PHONY: cluster create init setup start up
cluster create init setup start up:
	@idx=1; \
	for cluster in ${CLUSTERS}; do \
		echo "Creating cluster $$cluster..."; \
		kind create cluster --config kind.yaml --name $$cluster; \
		kubectl --context kind-$$cluster delete deploy -n kube-system coredns; \
		kubectl --context kind-$$cluster delete deploy -n local-path-storage local-path-provisioner; \
		docker exec $$cluster-control-plane crictl pull httpd > /dev/null; \
		idx=$$((idx + 1)); \
	done

.PHONY: cni cp copy
cni cp copy:
	@idx=1; \
	for cluster in ${CLUSTERS}; do \
		cni_name=$$(echo ${CNI_NAMES} | cut -d' ' -f$$idx); \
		conf_file=$$(echo ${CONF_FILES} | cut -d' ' -f$$idx); \
		echo "Installing CNI $$cni_name on $$cluster..."; \
		docker cp $$conf_file $$cluster-control-plane:/etc/cni/net.d/$$conf_file; \
		docker cp $$cni_name.sh $$cluster-control-plane:/opt/cni/bin/$$cni_name; \
		docker exec $$cluster-control-plane chmod +x /opt/cni/bin/$$cni_name; \
		idx=$$((idx + 1)); \
	done

.PHONY: build
build:
	@echo "Building node image..."
	docker build -t node:latest SMPC/node/
	@echo "Building orchestrator image..."
	docker build -t orchestrator:latest SMPC/orchestrator/

.PHONY: load-images images
load-images images: build
	@echo "Loading node image into ${CLUSTER_NAME1}, ${CLUSTER_NAME2}, ${CLUSTER_NAME3}..."
	kind load docker-image node:latest --name ${CLUSTER_NAME1}
	kind load docker-image node:latest --name ${CLUSTER_NAME2}
	kind load docker-image node:latest --name ${CLUSTER_NAME3}
	@echo "Loading orchestrator image into ${CLUSTER_NAME4}..."
	kind load docker-image orchestrator:latest --name ${CLUSTER_NAME4}

.PHONY: pods
node-pods: load-images
	kubectl --context kind-${CLUSTER_NAME1} apply -f SMPC/k8s-node0.yaml
	kubectl --context kind-${CLUSTER_NAME2} apply -f SMPC/k8s-node1.yaml
	kubectl --context kind-${CLUSTER_NAME3} apply -f SMPC/k8s-node2.yaml

.PHONY: connect-clusters
connect-clusters:
	@echo "Connecting clusters"
	@idx=1; \
	for cluster in ${CLUSTERS}; do \
		echo "Setting up routing for $$cluster..."; \
		docker cp node-routing.sh $$cluster-control-plane:/usr/local/bin/node-routing.sh; \
		docker exec $$cluster-control-plane chmod +x /usr/local/bin/node-routing.sh; \
		docker exec $$cluster-control-plane node-routing.sh $$idx; \
		idx=$$((idx + 1)); \
	done

.PHONY: node-pods
orch-pods: load-images
	kubectl --context kind-${CLUSTER_NAME4} apply -f SMPC/k8s-orchestrator.yaml

.PHONY: test
test:
	kubectl apply -f test.yaml
	@sleep 5
	@echo "\n------\n"
	kubectl get pods -o wide
	@echo "\n------\n"
	docker exec ${CLUSTER_NAME1}-control-plane curl -m 5 -s 10.244.1.20

.PHONY: clean clear
clean clear:
	- kubectl delete -f test.yaml --ignore-not-found
	@idx=1; \
	for cluster in ${CLUSTERS}; do \
		cni_name=$$(echo ${CNI_NAMES} | cut -d' ' -f$$idx); \
		conf_file=$$(echo ${CONF_FILES} | cut -d' ' -f$$idx); \
		docker exec $$cluster-control-plane rm -f /opt/cni/bin/$$cni_name; \
		docker exec $$cluster-control-plane rm -f /etc/cni/net.d/$$conf_file; \
		idx=$$((idx + 1)); \
	done

.PHONY: delete destroy down stop
delete destroy down stop:
	@for cluster in ${CLUSTERS}; do \
		echo "Deleting cluster $$cluster..."; \
		kind delete cluster --name $$cluster; \
	done
