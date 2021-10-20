PRESTO_VERSION := 0.263
PRESTO_SNAPSHOT_VERSION := 0.264-SNAPSHOT

.PHONY: build local push run down release

build:
	docker build --build-arg VERSION=${PRESTO_VERSION} -t ${DOCKERHUB_ID}/presto-base:${PRESTO_VERSION} presto-base
	docker build --build-arg VERSION=${PRESTO_VERSION} -t ${DOCKERHUB_ID}/presto-dbx-coordinator:${PRESTO_VERSION} presto-coordinator
	docker build --build-arg VERSION=${PRESTO_VERSION} -t ${DOCKERHUB_ID}/presto-dbx-worker:${PRESTO_VERSION} presto-worker

snapshot:
	docker build --build-arg VERSION=${PRESTO_SNAPSHOT_VERSION} --build-arg DOCKERHUB_ID=${DOCKERHUB_ID} -f presto-base/Dockerfile-dev -t ${DOCKERHUB_ID}/presto-base:${PRESTO_SNAPSHOT_VERSION} presto-base
	docker build --build-arg VERSION=${PRESTO_SNAPSHOT_VERSION} --build-arg DOCKERHUB_ID=${DOCKERHUB_ID} -t ${DOCKERHUB_ID}/presto-dbx-coordinator:${PRESTO_SNAPSHOT_VERSION} presto-dbx-coordinator
	docker build --build-arg VERSION=${PRESTO_SNAPSHOT_VERSION} --build-arg DOCKERHUB_ID=${DOCKERHUB_ID} -t ${DOCKERHUB_ID}/presto-dbx-worker:${PRESTO_SNAPSHOT_VERSION} presto-dbx-worker
	docker push ${DOCKERHUB_ID}/presto-base:$(PRESTO_SNAPSHOT_VERSION)
	docker push ${DOCKERHUB_ID}/presto-dbx-coordinator:$(PRESTO_SNAPSHOT_VERSION)
	docker push ${DOCKERHUB_ID}/presto-dbx-worker:$(PRESTO_SNAPSHOT_VERSION)

push: build
	docker push ${DOCKERHUB_ID}/presto-base:$(PRESTO_VERSION)
	docker push ${DOCKERHUB_ID}/presto-dbx-coordinator:$(PRESTO_VERSION)
	docker push ${DOCKERHUB_ID}/presto-dbx-worker:$(PRESTO_VERSION)
	sh ./update-readme.sh

run:
	PRESTO_VERSION=$(PRESTO_VERSION) DOCKERHUB_ID=${DOCKERHUB_ID} docker-compose up -d
	echo "Please check http://localhost:8080"

run-snapshot:
	PRESTO_VERSION=$(PRESTO_SNAPSHOT_VERSION) docker-compose up -d
	echo "Please check http://localhost:8080"

test: run
	./test-container.sh $(PRESTO_VERSION)

down:
	PRESTO_VERSION=$(PRESTO_VERSION) docker-compose down

down-snapshot:
	PRESTO_VERSION=$(PRESTO_SNAPSHOT_VERSION) docker-compose down

release:
	git tag -a ${PRESTO_VERSION} -m "Release ${PRESTO_VERSION}"
	git push --tags
