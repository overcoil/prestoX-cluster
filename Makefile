PRESTO_VERSION := 0.263

# set to save typing for the p/t targets towards the end of this Makefile
#TRINO_VER:=339

# moving onto 359 
TRINO_VER:=359
PRESTO_VER:=0.266-SNAPSHOT

# Venki's delta-dsr0.3 branch (for Presto) is version 0.266-SNAPSHOT
# The 339-delta branch (for Trino) is version 339
PRESTO_SNAPSHOT_VERSION := 0.266-SNAPSHOT
#PRESTO_SNAPSHOT_VERSION := 339

.PHONY: build local push run down release pcopy pdev ppush prun pdown pcli tcopy tdev tpush trun tdown tcli

build:
	docker build --build-arg VERSION=${PRESTO_VERSION} -t ${DOCKERHUB_ID}/presto-base:${PRESTO_VERSION} presto-base
	docker build --build-arg VERSION=${PRESTO_VERSION} -t ${DOCKERHUB_ID}/presto-dbx-coordinator:${PRESTO_VERSION} presto-coordinator
	docker build --build-arg VERSION=${PRESTO_VERSION} -t ${DOCKERHUB_ID}/presto-dbx-worker:${PRESTO_VERSION} presto-worker

# use this to build a set of dev images for either Presto or Trino
# note the use of Dockerfile-dev which merely ADD local copies of presto-cli-*-executable.jar & presto-server-*.tar.gz to the image

snapshot:
	docker build --build-arg VERSION=${PRESTO_SNAPSHOT_VERSION} --build-arg DOCKERHUB_ID=${DOCKERHUB_ID} -f presto-base/Dockerfile-dev -t ${DOCKERHUB_ID}/presto-base:${PRESTO_SNAPSHOT_VERSION} presto-base
	docker build --build-arg VERSION=${PRESTO_SNAPSHOT_VERSION} --build-arg DOCKERHUB_ID=${DOCKERHUB_ID} -t ${DOCKERHUB_ID}/presto-dbx-coordinator:${PRESTO_SNAPSHOT_VERSION} presto-dbx-coordinator
	docker build --build-arg VERSION=${PRESTO_SNAPSHOT_VERSION} --build-arg DOCKERHUB_ID=${DOCKERHUB_ID} -t ${DOCKERHUB_ID}/presto-dbx-worker:${PRESTO_SNAPSHOT_VERSION} presto-dbx-worker
#	docker push ${DOCKERHUB_ID}/presto-base:$(PRESTO_SNAPSHOT_VERSION)
#	docker push ${DOCKERHUB_ID}/presto-dbx-coordinator:$(PRESTO_SNAPSHOT_VERSION)
#	docker push ${DOCKERHUB_ID}/presto-dbx-worker:$(PRESTO_SNAPSHOT_VERSION)

push: build
#	docker push ${DOCKERHUB_ID}/presto-base:$(PRESTO_VERSION)
#	docker push ${DOCKERHUB_ID}/presto-dbx-coordinator:$(PRESTO_VERSION)
#	docker push ${DOCKERHUB_ID}/presto-dbx-worker:$(PRESTO_VERSION)
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


# we rely upon the different versioning schema to allow the two set of binaries to co-exist!
pcopy:
	cp ~/.m2/repository/com/facebook/presto/presto-server/0.266-SNAPSHOT/presto-server-0.266-SNAPSHOT.tar.gz presto-base/
	cp ~/.m2/repository/com/facebook/presto/presto-cli/0.266-SNAPSHOT/presto-cli-0.266-SNAPSHOT-executable.jar presto-base/
	ls -l presto-base/presto-*

tcopy:
	cp ~/.m2/repository/io/trino/trino-server/${TRINO_VER}/trino-server-${TRINO_VER}.tar.gz presto-base/trino-server-${TRINO_VER}.tar.gz
	cp ~/.m2/repository/io/trino/trino-cli/${TRINO_VER}/trino-cli-${TRINO_VER}-executable.jar presto-base/trino-cli-${TRINO_VER}-executable.jar
	chmod +x presto-base/trino-cli-${TRINO_VER}-executable.jar
	ls -l presto-base/trino-*

pcli:
	docker exec -it coordinator /usr/local/bin/presto-cli

tcli:
	docker exec -it coordinator /usr/local/bin/trino-cli


# Presto dev build
pdev:
	docker build --build-arg VERSION=${PRESTO_VER} --build-arg DOCKERHUB_ID=${DOCKERHUB_ID} \
		--build-arg PKG_REPO_SUBPATH=com/facebook/presto --build-arg PRESTVAR=presto \
		-f presto-base/Dockerfile-dev -t ${DOCKERHUB_ID}/presto-base:${PRESTO_VER} presto-base
	docker build --build-arg VERSION=${PRESTO_VER} --build-arg DOCKERHUB_ID=${DOCKERHUB_ID} \
		-f presto-dbx-coordinator/Dockerfile-presto \
		-t ${DOCKERHUB_ID}/presto-dbx-coordinator:${PRESTO_VER} presto-dbx-coordinator
	docker build --build-arg VERSION=${PRESTO_VER} --build-arg DOCKERHUB_ID=${DOCKERHUB_ID} \
		-f presto-dbx-worker/Dockerfile-presto \
		-t ${DOCKERHUB_ID}/presto-dbx-worker:${PRESTO_VER} presto-dbx-worker

ppush:
	docker push ${DOCKERHUB_ID}/presto-base:$(PRESTO_VER)
	docker push ${DOCKERHUB_ID}/presto-dbx-coordinator:$(PRESTO_VER)
	docker push ${DOCKERHUB_ID}/presto-dbx-worker:$(PRESTO_VER)

prun:
	PRESTVAR=presto PRESTO_VERSION=$(PRESTO_VER) docker-compose up -d
	echo "PrestoDB up. Please check http://localhost:8080"

pdown:
	PRESTVAR=presto PRESTO_VERSION=$(PRESTO_VER) docker-compose down

# Trino dev build
tdev:
	docker build --build-arg VERSION=${TRINO_VER} --build-arg DOCKERHUB_ID=${DOCKERHUB_ID} \
		--build-arg PKG_REPO_SUBPATH=io/trino --build-arg PRESTVAR=trino \
		-f presto-base/Dockerfile-dev -t ${DOCKERHUB_ID}/trino-base:${TRINO_VER} presto-base
	docker build --build-arg VERSION=${TRINO_VER} --build-arg DOCKERHUB_ID=${DOCKERHUB_ID} \
		-f presto-dbx-coordinator/Dockerfile-trino \
		-t ${DOCKERHUB_ID}/trino-dbx-coordinator:${TRINO_VER} presto-dbx-coordinator
	docker build --build-arg VERSION=${TRINO_VER} --build-arg DOCKERHUB_ID=${DOCKERHUB_ID} \
		-f presto-dbx-worker/Dockerfile-trino \
		-t ${DOCKERHUB_ID}/trino-dbx-worker:${TRINO_VER} presto-dbx-worker

tpush:
	docker push ${DOCKERHUB_ID}/trino-base:$(TRINO_VER)
	docker push ${DOCKERHUB_ID}/trino-dbx-coordinator:$(TRINO_VER)
	docker push ${DOCKERHUB_ID}/trino-dbx-worker:$(TRINO_VER)

trun:
	PRESTVAR=trino PRESTO_VERSION=$(TRINO_VER) docker-compose up -d
	echo "Trino up. Please check http://localhost:8080"

tdown:
	PRESTVAR=trino PRESTO_VERSION=$(TRINO_VER) docker-compose down


