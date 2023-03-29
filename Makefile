UPSTREAM_MINIMAL_NOTEBOOK_VER=6e246ea4bbff  # 2021-11-20
UPSTREAM_SCIPY_NOTEBOOK_VER=d113a601dbb8  # Image updated 2020-12-26
CRAN_URL=https://cran.microsoft.com/snapshot/2022-08-19/

# base image - jupyter stuff only, not much software
VER_BASE=5.0
# Python
VER_STD=5.0.24
# Julia
VER_JULIA=5.0.16
# R
VER_R=5.0.25-dev2-config
# OpenCV
VER_CV=1.8.0

PACK_PATH=/m/scicomp/software/anaconda-ci/aalto-jupyter-anaconda/packs
ENVIRONMENT_NAME=jupyter-generic
ENVIRONMENT_VERSION=2022-03-07
ENVIRONMENT_HASH=560c880a
CONDA_FILE=$(ENVIRONMENT_NAME)_$(ENVIRONMENT_VERSION)_$(ENVIRONMENT_HASH).tar.gz

# VER2_R=$(VER_R)-$(GIT_REV)
TEST_MEM_LIMIT="--memory=2G"
R_INSTALL_JOB_COUNT=10

# For private registry, run: `make REGISTRY=registry.cs.aalto.fi/ GROUP=jupyter [..]`
REGISTRY=                   # use the form "registry.cs.aalto.fi/"
# REGISTRY=registry.cs.aalto.fi/
GROUP=aaltoscienceit
# GROUP=jupyter

.PHONY: default

default:
	echo "Please specify a command to run"

full-rebuild: base standard test-standard


base: no-pack pre-build
	@! grep -P '\t' -C 1 base.Dockerfile || { echo "ERROR: Tabs in base.Dockerfile" ; exit 1 ; }
	DOCKER_BUILDKIT=1 docker build -t ${REGISTRY}${GROUP}/notebook-server-base:$(VER_BASE) . -f base.Dockerfile --build-arg=UPSTREAM_MINIMAL_NOTEBOOK_VER=$(UPSTREAM_MINIMAL_NOTEBOOK_VER)
	docker run --rm ${REGISTRY}${GROUP}/notebook-server-base:$(VER_BASE) conda env export -n base > environment-yml/$@-$(VER_BASE).yml
	docker run --rm ${REGISTRY}${GROUP}/notebook-server-base:$(VER_BASE) conda list --revisions > conda-history/$@-$(VER_BASE).yml
standard: | include-pack build-standard no-pack
build-standard: pre-build
	@! grep -P '\t' -C 1 standard.Dockerfile || { echo "ERROR: Tabs in standard.Dockerfile" ; exit 1 ; }
	mkdir -p conda
# NOTE: This is a temporary workaround. It would be more efficient to create
#       the archives directly with the correct permissions
	if ! [ -e "conda/${CONDA_FILE}" ]; then \
		rm -rf conda/unpack && \
		mkdir -p conda/unpack && \
		tar xf $(PACK_PATH)/${CONDA_FILE} -C conda/unpack && \
		chmod -R g+rwX conda/unpack && \
		find conda/unpack -type d -exec chmod +6000 {} \; && \
		tar -czf conda/${CONDA_FILE} --owner=1000 --group=100 -C conda/unpack . ; \
	fi
	DOCKER_BUILDKIT=1 docker build -t ${REGISTRY}${GROUP}/notebook-server:$(VER_STD) . \
		-f standard.Dockerfile \
		--build-arg=VER_BASE=$(VER_BASE) \
		--build-arg=ENVIRONMENT_NAME=$(ENVIRONMENT_NAME) \
		--build-arg=ENVIRONMENT_VERSION=$(ENVIRONMENT_VERSION) \
		--build-arg=ENVIRONMENT_HASH=$(ENVIRONMENT_HASH) \
		--build-arg=VER_STD=$(VER_STD)
	#docker run --rm ${REGISTRY}${GROUP}/notebook-server:$(VER_STD) conda env export -n base > environment-yml/$@-$(VER_STD).yml
	#docker run --rm ${REGISTRY}${GROUP}/notebook-server:$(VER_STD) conda list --revisions > conda-history/$@-$(VER_STD).yml
#r:
#	DOCKER_BUILDKIT=1 docker build -t ${REGISTRY}${GROUP}/notebook-server-r:0.4.0 --pull=false . -f r.Dockerfile
r-ubuntu: pre-build
	@! grep -P '\t' -C 1 r-ubuntu.Dockerfile || { echo "ERROR: Tabs in r-ubuntu.Dockerfile" ; exit 1 ; }
	DOCKER_BUILDKIT=1 docker build -t ${REGISTRY}${GROUP}/notebook-server-r-ubuntu:$(VER_R) --pull=false . -f r-ubuntu.Dockerfile --build-arg=VER_BASE=$(VER_BASE) --build-arg=CRAN_URL=$(CRAN_URL) --build-arg=INSTALL_JOB_COUNT=$(R_INSTALL_JOB_COUNT)
#	#docker run --rm ${REGISTRY}${GROUP}/notebook-server-r-ubuntu:$(VER_R) conda env export -n base > environment-yml/$@-$(VER_R).yml
	docker run --rm ${REGISTRY}${GROUP}/notebook-server-r-ubuntu:$(VER_R) conda list --revisions > conda-history/$@-$(VER_R).yml
julia: pre-build
	@! grep -P '\t' -C 1 julia.Dockerfile || { echo "ERROR: Tabs in julia.Dockerfile" ; exit 1 ; }
	DOCKER_BUILDKIT=1 docker build -t ${REGISTRY}${GROUP}/notebook-server-julia:$(VER_JULIA) --pull=false . -f julia.Dockerfile --build-arg=VER_BASE=$(VER_BASE)
	docker run --rm ${REGISTRY}${GROUP}/notebook-server-julia:$(VER_JULIA) conda env export -n base > environment-yml/$@-$(VER_JULIA).yml
	docker run --rm ${REGISTRY}${GROUP}/notebook-server-julia:$(VER_JULIA) conda list --revisions > conda-history/$@-$(VER_JULIA).yml
opencv: pre-build
	@! grep -P '\t' -C 1 opencv.Dockerfile || { echo "ERROR: Tabs in opencv.Dockerfile" ; exit 1 ; }
	DOCKER_BUILDKIT=1 docker build -t notebook-server-opencv:$(VER_CV) --pull=false . -f opencv.Dockerfile --build-arg=VER_STD=$(VER_STD)
	docker run --rm notebook-server-opencv:$(VER_CV) conda env export -n base > environment-yml/$@-$(VER_CV).yml
	docker run --rm ${REGISTRY}${GROUP}/notebook-server:$(VER_CV) conda list --revisions > conda-history/$@-$(VER_CV).yml


pre-test:
	$(eval TEST_DIR := $(shell mktemp -d /tmp/pytest.XXXXXX))
	rsync --chmod=Do+x,+r -a --delete tests/ $(TEST_DIR)

test-standard: pre-test
	docker run --volume=$(TEST_DIR):/tests:ro ${TEST_MEM_LIMIT} ${REGISTRY}${GROUP}/notebook-server:$(VER_STD) pytest -o cache_dir=/tmp/pytestcache /tests/python/${TESTFILE} ${TESTARGS}
	rm -r $(TEST_DIR)
#	CC="clang" CXX="clang++" jupyter nbconvert --exec --ExecutePreprocessor.timeout=300 pystan_demo.ipynb --stdout
test-standard-full: test-standard pre-test
	docker run --volume=/tmp/nbs-tests:/tests:ro ${TEST_MEM_LIMIT} ${REGISTRY}${GROUP}/notebook-server:$(VER_STD) bash -c 'cd /tmp ; git clone https://github.com/avehtari/BDA_py_demos ; cd BDA_py_demos/demos_pystan/ ; CC=clang CXX=clang++ jupyter nbconvert --exec --ExecutePreprocessor.timeout=300 pystan_demo.ipynb --stdout > /dev/null'
	rm -r $(TEST_DIR)
	@echo
	@echo
	@echo
	@echo "All tests passed..."

test-r-ubuntu: r-ubuntu pre-test
	docker run --volume=$(TEST_DIR):/tests:ro ${TEST_MEM_LIMIT} ${REGISTRY}${GROUP}/notebook-server-r-ubuntu:$(VER_R) Rscript /tests/r/test_bayes.r
	rm -r $(TEST_DIR)



push-standard: standard
	docker push ${REGISTRY}${GROUP}/notebook-server:$(VER_STD)
push-r-ubuntu: r-ubuntu
	docker push ${REGISTRY}${GROUP}/notebook-server-r-ubuntu:$(VER_R)
push-julia: julia
#	time docker save ${REGISTRY}${GROUP}/notebook-server-julia:${VER_JULIA} | ssh manager ssh jupyter-k8s-node4.cs.aalto.fi 'docker load'
	docker push ${REGISTRY}${GROUP}/notebook-server-julia:$(VER_JULIA)
push-dev: check-khost standard
	## NOTE: Saving and loading the whole image takes a long time. Pushing
	##       partial changes to a DockerHub repo using `push-devhub` is faster
	# time docker save ${REGISTRY}${GROUP}/notebook-server-r-ubuntu:${VER_STD} | ssh ${KHOST} ssh jupyter-k8s-node4.cs.aalto.fi 'docker load'
	time docker save ${REGISTRY}${GROUP}/notebook-server:${VER_STD} | ssh ${KHOST} ssh k8s-node4.cs.aalto.fi 'docker load'
push-devhub: check-khost check-hubrepo standard
	docker tag ${REGISTRY}${GROUP}/notebook-server:${VER_STD} ${HUBREPO}/notebook-server:${VER_STD}
	docker push ${HUBREPO}/notebook-server:${VER_STD}
	ssh ${KHOST} ssh k8s-node4.cs.aalto.fi "docker pull ${HUBREPO}/notebook-server:${VER_STD}"
push-devhub-base: check-khost check-hubrepo base
	docker tag ${REGISTRY}${GROUP}/notebook-server-base:${VER_BASE} ${HUBREPO}/notebook-server-base:${VER_BASE}
	docker push ${HUBREPO}/notebook-server-base:${VER_BASE}
	ssh ${KHOST} ssh k8s-node4.cs.aalto.fi "docker pull ${HUBREPO}/notebook-server-base:${VER_BASE}"

pull-standard: check-khost check-knodes
	ssh ${KHOST} time pdsh -R ssh -w ${KNODES} "docker pull ${REGISTRY}${GROUP}/notebook-server:${VER_STD}"
	ssh ${KHOST} time pdsh -R ssh -w ${KNODES} "docker tag ${REGISTRY}${GROUP}/notebook-server:${VER_STD} ${REGISTRY}${GROUP}/notebook-server:${VER_STD}"
pull-r-ubuntu: check-khost check-knodes
	ssh ${KHOST} time pdsh -R ssh -w ${KNODES} "docker pull ${REGISTRY}${GROUP}/notebook-server-r-ubuntu:${VER_R}"
	ssh ${KHOST} time pdsh -R ssh -w ${KNODES} "docker tag ${REGISTRY}${GROUP}/notebook-server-r-ubuntu:${VER_R} ${REGISTRY}${GROUP}/notebook-server-r-ubuntu:${VER_R}"
pull-julia: check-khost check-knodes
	ssh ${KHOST} time pdsh -R ssh -w ${KNODES} "docker pull ${REGISTRY}${GROUP}/notebook-server-julia:${VER_JULIA}"
	ssh ${KHOST} time pdsh -R ssh -w ${KNODES} "docker tag ${REGISTRY}${GROUP}/notebook-server-julia:${VER_JULIA} ${REGISTRY}${GROUP}/notebook-server-julia:${VER_JULIA}"

pull-standard-dev:
	ssh 3 ctr -n k8s.io images pull ${REGISTRY}${GROUP}/notebook-server:${VER_STD}
pull-r-dev: push-r-ubuntu
	ssh 3 ctr -n k8s.io images pull ${REGISTRY}${GROUP}/notebook-server-r-ubuntu:${VER_R}

# Clean up disk space
prune-images: check-khost check-knodes
#	ssh ${KHOST} time pdsh -R ssh -w ${KNODES} 'docker rmi ${REGISTRY}${GROUP}/notebook-server:0.5.{0,1,2,3,4,5,6,7}'
	ssh ${KHOST} time pdsh -R ssh -w ${KNODES} 'docker image prune -f'
	ssh ${KHOST} time pdsh -R ssh -w ${KNODES} 'docker container prune -f'
	ssh ${KHOST} time pdsh -R ssh -w ${KNODES} 'docker images' | cut '-d:' '-f2-' | sort

# Aborts the process if necessary environment variables are not set
# https://stackoverflow.com/a/4731504/3005969
check-khost:
ifndef KHOST
	$(error KHOST is undefined. Format: KHOST=user@kubernetes_host.tld)
endif

check-knodes:
ifndef KNODES
	$(error KNODES is undefined. Format: KNODES=kubernetes-node[1-n].tld)
endif

check-hubrepo:
ifndef HUBREPO
	$(error HUBREPO is undefined. Format: HUBREPO=dockerhub_repo_name)
endif

no-pack:
	$(no-pack)

define no-pack =
	sed -i '\,^!conda/.*\.tar.gz,d' .dockerignore
endef

include-pack:
	$(no-pack)
	echo '!conda/${CONDA_FILE}' >> .dockerignore

pre-build:
	mkdir -p conda-history environment-yml
