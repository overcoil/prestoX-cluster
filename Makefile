PRESTO_VERSION := 0.263
PRESTO_SNAPSHOT_VERSION := 0.263-snapshot

.PHONY: build local push run down release

build:
	docker build --build-arg VERSION=${PRESTO_VERSION} -t saj1th/presto-base:${PRESTO_VERSION} presto-base
	docker build --build-arg VERSION=${PRESTO_VERSION} -t saj1th/presto-dbx-coordinator:${PRESTO_VERSION} presto-coordinator
	docker build --build-arg VERSION=${PRESTO_VERSION} -t saj1th/presto-dbx-worker:${PRESTO_VERSION} presto-worker

snapshot:
	docker build --build-arg VERSION=${PRESTO_SNAPSHOT_VERSION} -f presto-base/Dockerfile-dev -t saj1th/presto-base:${PRESTO_SNAPSHOT_VERSION} presto-base
	docker build --build-arg VERSION=${PRESTO_SNAPSHOT_VERSION} -t saj1th/presto-dbx-coordinator:${PRESTO_SNAPSHOT_VERSION} presto-dbx-coordinator
	docker build --build-arg VERSION=${PRESTO_SNAPSHOT_VERSION} -t saj1th/presto-dbx-worker:${PRESTO_SNAPSHOT_VERSION} presto-dbx-worker
	docker push saj1th/presto-base:$(PRESTO_SNAPSHOT_VERSION)
	docker push saj1th/presto-dbx-coordinator:$(PRESTO_SNAPSHOT_VERSION)
	docker push saj1th/presto-dbx-worker:$(PRESTO_SNAPSHOT_VERSION)

push: build
	docker push saj1th/presto-base:$(PRESTO_VERSION)
	docker push saj1th/presto-dbx-coordinator:$(PRESTO_VERSION)
	docker push saj1th/presto-dbx-worker:$(PRESTO_VERSION)
	sh ./update-readme.sh

run:
	PRESTO_VERSION=$(PRESTO_VERSION) docker-compose up -d
	echo "Please check http://localhost:8080"

test: run
	./test-container.sh $(PRESTO_VERSION)

down:
	PRESTO_VERSION=$(PRESTO_VERSION) docker-compose down

release:
	git tag -a ${PRESTO_VERSION} -m "Release ${PRESTO_VERSION}"
	git push --tags
